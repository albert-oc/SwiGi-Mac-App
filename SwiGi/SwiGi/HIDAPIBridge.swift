import Foundation
import CHIDAPI

enum HIDAPIBridge {
    private static var initialized = false

    static func initialize() {
        guard !initialized else { return }
        hid_init()
        hid_darwin_set_open_exclusive(0)
        initialized = true
    }

    static func lastError(device: OpaquePointer? = nil) -> String {
        guard let message = hid_error(device) else { return "unknown hidapi error" }
        return withUnsafePointer(to: message) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}
