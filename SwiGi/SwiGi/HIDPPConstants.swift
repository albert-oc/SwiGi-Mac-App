import Foundation

enum HIDPPConstants {
    static let logitechVID: UInt16 = 0x046D

    static let boltPID: UInt16 = 0xC548
    static let unifyingPIDs: [UInt16] = [0xC52B, 0xC532]
    static let allReceiverPIDs: Set<UInt16> = Set([boltPID] + unifyingPIDs)

    static let reportShort: UInt8 = 0x10
    static let reportLong: UInt8 = 0x11
    static let msgShortLen = 7
    static let msgLongLen = 20
    static let maxReadSize = 32

    static let featureRoot: UInt16 = 0x0000
    static let featureDeviceTypeAndName: UInt16 = 0x0005
    static let featureChangeHost: UInt16 = 0x1814

    static let deviceTypeKeyboard: UInt8 = 0
    static let deviceTypeMouse: UInt8 = 3
    static let deviceTypeTrackpad: UInt8 = 4
    static let deviceTypeTrackball: UInt8 = 5

    static let devnumberDirect: UInt8 = 0xFF
    static let swID: UInt8 = 0x0A
    static let changeHostFnSet: UInt8 = 0x10

    static let msgLengths: [UInt8: Int] = [
        reportShort: msgShortLen,
        reportLong: msgLongLen
    ]

    static let directUsagePairs: Set<UInt32> = [
        0xFF00 << 16 | 0x0002,
        0xFF43 << 16 | 0x0202,
        0xFF0C << 16 | 0x0001,
        0x0001 << 16 | 0x0006,
        0x0001 << 16 | 0x0002
    ]

    static func usagePairKey(page: UInt16, usage: UInt16) -> UInt32 {
        UInt32(page) << 16 | UInt32(usage)
    }
}
