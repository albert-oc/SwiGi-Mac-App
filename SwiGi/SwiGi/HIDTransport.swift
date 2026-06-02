import Foundation
import CHIDAPI

enum TransportError: LocalizedError {
    case closed
    case readFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .closed:
            return "Transport is closed"
        case .readFailed(let message):
            return "HID read failed: \(message)"
        case .writeFailed(let message):
            return "HID write failed: \(message)"
        }
    }
}

final class HIDTransport {
    let path: String
    let pid: UInt16
    private var device: OpaquePointer?

    init(path: String, pid: UInt16) throws {
        self.path = path
        self.pid = pid
        guard let dev = path.withCString({ hid_open_path($0) }) else {
            throw TransportError.readFailed(HIDAPIBridge.lastError())
        }
        device = dev
    }

    func read(timeout: Int = 500) throws -> Data? {
        guard let device else { throw TransportError.closed }
        var buffer = [UInt8](repeating: 0, count: HIDPPConstants.maxReadSize)
        let count = buffer.withUnsafeMutableBufferPointer { ptr in
            hid_read_timeout(device, ptr.baseAddress, HIDPPConstants.maxReadSize, Int32(timeout))
        }
        if count < 0 {
            let err = HIDAPIBridge.lastError(device: device)
            if err.lowercased().contains("success") || err.isEmpty {
                return nil
            }
            throw TransportError.readFailed(err)
        }
        guard count > 0 else { return nil }
        return Data(buffer.prefix(Int(count)))
    }

    func write(_ message: Data) throws {
        guard let device else { throw TransportError.closed }
        let count = message.withUnsafeBytes { ptr in
            hid_write(device, ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), message.count)
        }
        if count < 0 {
            throw TransportError.writeFailed(HIDAPIBridge.lastError(device: device))
        }
    }

    func close() {
        if let device {
            hid_close(device)
            self.device = nil
        }
    }

    deinit {
        close()
    }

    var isOpen: Bool { device != nil }
}
