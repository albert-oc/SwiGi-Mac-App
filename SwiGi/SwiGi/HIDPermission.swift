import IOKit.hid

enum HIDPermission {
  static var isGranted: Bool {
    IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
  }

  /// Prompts for Input Monitoring if needed. Returns whether access is granted.
  @discardableResult
  static func requestInputMonitoring() -> Bool {
    switch IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) {
    case kIOHIDAccessTypeGranted:
      return true
    case kIOHIDAccessTypeDenied:
      return false
    default:
      return IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }
  }

  static let settingsHint =
    "Enable SwiGi in System Settings → Privacy & Security → Input Monitoring, then try Start again."
}
