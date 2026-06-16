import Foundation
import CHIDAPI

struct DeviceInfo {
    let transport: HIDTransport
    let name: String
    let pid: UInt16
    let changeHostIndex: UInt8

    mutating func close() {
        transport.close()
    }
}

enum DeviceDiscovery {
    static func findDevice(wantedType: UInt8) -> DeviceInfo? {
        guard let head = hid_enumerate(HIDPPConstants.logitechVID, 0) else { return nil }
        defer { hid_free_enumeration(head) }

        var candidates: [(score: Int, path: String, pid: UInt16, usagePage: UInt16, usage: UInt16)] = []
        var node: UnsafeMutablePointer<hid_device_info>? = head

        while let current = node {
            let info = current.pointee
            node = info.next

            let pid = info.product_id
            let usagePage = info.usage_page
            let usage = info.usage

            if HIDPPConstants.allReceiverPIDs.contains(pid) { continue }
            let pairKey = HIDPPConstants.usagePairKey(page: usagePage, usage: usage)
            guard HIDPPConstants.directUsagePairs.contains(pairKey) else { continue }

            let score = [0xFF00, 0xFF43, 0xFF0C].contains(usagePage) ? 100 : 0
            let path = String(cString: info.path)
            candidates.append((score, path, pid, usagePage, usage))
        }

        candidates.sort { $0.score > $1.score }

        var foundPIDs = Set<UInt16>()
        for candidate in candidates {
            if foundPIDs.contains(candidate.pid) { continue }

            let transport: HIDTransport
            do {
                transport = try HIDTransport(path: candidate.path, pid: candidate.pid)
            } catch {
                continue
            }

            do {
                guard let featureIndex = HIDPPProtocol.resolveFeature(
                    transport: transport,
                    devnumber: HIDPPConstants.devnumberDirect,
                    featureCode: HIDPPConstants.featureDeviceTypeAndName
                ) else {
                    transport.close()
                    continue
                }

                guard let deviceType = HIDPPProtocol.getDeviceType(
                    transport: transport,
                    devnumber: HIDPPConstants.devnumberDirect,
                    featureIndex: featureIndex
                ) else {
                    transport.close()
                    continue
                }

                let name = HIDPPProtocol.getDeviceName(
                    transport: transport,
                    devnumber: HIDPPConstants.devnumberDirect,
                    featureIndex: featureIndex
                ) ?? "Logitech-0x\(String(format: "%04X", candidate.pid))"

                let isMouse = [HIDPPConstants.deviceTypeMouse, HIDPPConstants.deviceTypeTrackpad, HIDPPConstants.deviceTypeTrackball]
                    .contains(deviceType)

                if wantedType == HIDPPConstants.deviceTypeKeyboard, deviceType != HIDPPConstants.deviceTypeKeyboard {
                    transport.close()
                    continue
                }
                if wantedType == HIDPPConstants.deviceTypeMouse, !isMouse {
                    transport.close()
                    continue
                }

                guard let changeHostIndex = HIDPPProtocol.resolveFeature(
                    transport: transport,
                    devnumber: HIDPPConstants.devnumberDirect,
                    featureCode: HIDPPConstants.featureChangeHost
                ) else {
                    transport.close()
                    continue
                }

                foundPIDs.insert(candidate.pid)
                return DeviceInfo(
                    transport: transport,
                    name: name,
                    pid: candidate.pid,
                    changeHostIndex: changeHostIndex
                )
            } catch {
                transport.close()
                continue
            }
        }

        return nil
    }

    /// Lists Logitech HID interfaces visible to hidapi (for troubleshooting logs).
    static func scanSummary() -> String {
        guard let head = hid_enumerate(HIDPPConstants.logitechVID, 0) else {
            return "No Logitech HID devices visible to hidapi."
        }
        defer { hid_free_enumeration(head) }

        var lines: [String] = []
        var node: UnsafeMutablePointer<hid_device_info>? = head
        while let current = node {
            let info = current.pointee
            node = info.next
            let pid = info.product_id
            if HIDPPConstants.allReceiverPIDs.contains(pid) { continue }
            let pairKey = HIDPPConstants.usagePairKey(page: info.usage_page, usage: info.usage)
            let path = String(cString: info.path)
            let supported = HIDPPConstants.directUsagePairs.contains(pairKey) ? "ok" : "skip"
            lines.append(
                "  pid=0x\(String(format: "%04X", pid)) usage=0x\(String(format: "%04X", info.usage_page)):\(String(format: "%04X", info.usage)) [\(supported)] \(path)"
            )
        }
        if lines.isEmpty {
            return "No Logitech HID devices visible to hidapi (check Bluetooth and Input Monitoring)."
        }
        return "Logitech HID scan:\n" + lines.joined(separator: "\n")
    }
}
