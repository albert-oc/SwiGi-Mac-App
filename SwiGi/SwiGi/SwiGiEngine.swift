import Foundation
import os

@MainActor
final class SwiGiEngine: ObservableObject {
    enum Status: Equatable {
        case stopped
        case starting
        case running(keyboard: String, mouse: String, switchCount: Int)
        case error(String)
    }

    @Published private(set) var status: Status = .stopped
    @Published var verboseLogging = false

    var onLog: (@Sendable (String, OSLogType) -> Void)?

    private var workerTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.swigi.app", category: "engine")

    var isRunning: Bool {
        if case .running = status { return true }
        if case .starting = status { return true }
        return false
    }

    func start() {
        guard workerTask == nil else { return }
        status = .starting
        workerTask = Task.detached(priority: .userInitiated) { [weak self] in
            await self?.runLoop()
        }
    }

    func stop() {
        workerTask?.cancel()
        workerTask = nil
        status = .stopped
    }

    private func runLoop() async {
        HIDAPIBridge.initialize()

        await updateStatus(.starting)

        if !HIDPermission.isGranted {
            _ = HIDPermission.requestInputMonitoring()
        }
        if !HIDPermission.isGranted {
            log("Input Monitoring permission not granted", level: .error)
            await updateStatus(.error("Input Monitoring permission required. \(HIDPermission.settingsHint)"))
            workerTask = nil
            return
        }

        log("SwiGi — searching for devices...", level: .info)

        guard var keyboard = await findDeviceWithRetry(
            wantedType: HIDPPConstants.deviceTypeKeyboard,
            label: "keyboard"
        ) else {
            log(DeviceDiscovery.scanSummary(), level: .info)
            await updateStatus(.error(
                "Keyboard not found. Confirm it is connected via Bluetooth and supports Easy-Switch. \(HIDPermission.settingsHint)"
            ))
            workerTask = nil
            return
        }

        guard var mouse = await findDeviceWithRetry(
            wantedType: HIDPPConstants.deviceTypeMouse,
            label: "mouse"
        ) else {
            keyboard.close()
            log(DeviceDiscovery.scanSummary(), level: .info)
            await updateStatus(.error(
                "Mouse not found. Confirm it is connected via Bluetooth and supports Easy-Switch. \(HIDPermission.settingsHint)"
            ))
            workerTask = nil
            return
        }

        log("Keyboard: \(keyboard.name) (CHANGE_HOST idx=\(keyboard.changeHostIndex))", level: .info)
        log("Mouse: \(mouse.name) (CHANGE_HOST idx=\(mouse.changeHostIndex))", level: .info)
        log("Ready. Press Easy-Switch on \(keyboard.name).", level: .info)

        var totalSwitches = 0
        var lastResponse = Date()
        let watchdogTimeout: TimeInterval = 10

        await updateStatus(.running(keyboard: keyboard.name, mouse: mouse.name, switchCount: totalSwitches))

        while !Task.isCancelled {
            if Date().timeIntervalSince(lastResponse) > watchdogTimeout {
                log("Watchdog: no response for \(Int(watchdogTimeout))s, reconnecting...", level: .info)
                keyboard.close()
                mouse.close()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let kb = DeviceDiscovery.findDevice(wantedType: HIDPPConstants.deviceTypeKeyboard) {
                    keyboard = kb
                    log("Watchdog reconnect: \(keyboard.name)", level: .info)
                }
                lastResponse = Date()
                continue
            }

            do {
                try keyboard.transport.write(HIDPPProtocol.ping)
            } catch {
                log("Keyboard disconnected, waiting for reconnect...", level: .info)
                keyboard.close()

                var kbNew: DeviceInfo?
                for attempt in 0..<120 where !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    kbNew = DeviceDiscovery.findDevice(wantedType: HIDPPConstants.deviceTypeKeyboard)
                    if kbNew != nil { break }
                    if attempt % 20 == 19 {
                        log("Reconnect attempt \(attempt + 1)/120...", level: .debug)
                    }
                }

                guard let kbNew else {
                    log("Keyboard did not return, retrying...", level: .default)
                    continue
                }

                keyboard = kbNew
                log("Keyboard reconnect: \(keyboard.name)", level: .info)
                lastResponse = Date()
                mouse.close()
                log("Closed stale mouse transport; will reconnect on next event", level: .debug)
                continue
            }

            let deadline = Date().addingTimeInterval(0.08)
            while Date() < deadline, !Task.isCancelled {
                let raw: Data
                do {
                    guard let data = try keyboard.transport.read(timeout: 25) else { continue }
                    raw = data
                } catch {
                    break
                }

                guard raw.count >= 4 else { continue }
                let reportID = raw[0]
                guard let expectedLen = HIDPPConstants.msgLengths[reportID], raw.count == expectedLen else { continue }

                let feature = raw[2]
                let function = raw[3]
                let swID = function & 0x0F
                lastResponse = Date()

                if feature == keyboard.changeHostIndex, swID == 0, raw.count > 5 {
                    let targetHost = raw[5]
                    log("Easy-Switch: \(keyboard.name) → host \(targetHost)", level: .info)

                    if !mouse.transport.isOpen {
                        log("Mouse transport stale, reconnecting...", level: .debug)
                        if let newMouse = DeviceDiscovery.findDevice(wantedType: HIDPPConstants.deviceTypeMouse) {
                            mouse = newMouse
                        } else {
                            log("Mouse unavailable — will switch on next Easy-Switch", level: .info)
                            break
                        }
                    }

                    do {
                        try HIDPPProtocol.sendChangeHost(
                            transport: mouse.transport,
                            devnumber: HIDPPConstants.devnumberDirect,
                            featureIndex: mouse.changeHostIndex,
                            targetHost: targetHost
                        )
                        totalSwitches += 1
                        log("CHANGE_HOST → \(mouse.name) → host \(targetHost)", level: .info)
                        await updateStatus(.running(keyboard: keyboard.name, mouse: mouse.name, switchCount: totalSwitches))
                    } catch {
                        log("CHANGE_HOST to mouse failed, reconnecting mouse...", level: .default)
                        mouse.close()
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        if let newMouse = DeviceDiscovery.findDevice(wantedType: HIDPPConstants.deviceTypeMouse) {
                            mouse = newMouse
                            do {
                                try HIDPPProtocol.sendChangeHost(
                                    transport: mouse.transport,
                                    devnumber: HIDPPConstants.devnumberDirect,
                                    featureIndex: mouse.changeHostIndex,
                                    targetHost: targetHost
                                )
                                totalSwitches += 1
                                log("CHANGE_HOST → \(mouse.name) → host \(targetHost) (after reconnect)", level: .info)
                                await updateStatus(.running(keyboard: keyboard.name, mouse: mouse.name, switchCount: totalSwitches))
                            } catch {
                                log("CHANGE_HOST retry failed — mouse will switch next time", level: .default)
                            }
                        } else {
                            log("Mouse unavailable — will switch on next Easy-Switch", level: .info)
                        }
                    }
                    break
                }

                if swID == 0 {
                    log("Notification: feat=0x\(String(format: "%02X", feature)) [\(raw.prefix(10).map { String(format: "%02x", $0) }.joined())]", level: .debug)
                }
            }

            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        log("Stopping. Total switches: \(totalSwitches)", level: .info)
        keyboard.close()
        mouse.close()
        await updateStatus(.stopped)
        workerTask = nil
    }

    private func updateStatus(_ newStatus: Status) async {
        await MainActor.run {
            status = newStatus
        }
    }

    private func findDeviceWithRetry(wantedType: UInt8, label: String) async -> DeviceInfo? {
        for attempt in 1...60 {
            if Task.isCancelled { return nil }
            if let device = DeviceDiscovery.findDevice(wantedType: wantedType) {
                return device
            }
            if attempt == 1 || attempt % 10 == 0 {
                log("Still searching for \(label)... (\(attempt)/60)", level: .info)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        return nil
    }

    private func log(_ message: String, level: OSLogType) {
        if level == .debug, !verboseLogging { return }
        logger.log(level: level, "\(message, privacy: .public)")
        onLog?(message, level)
    }
}
