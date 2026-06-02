namespace SwiGi.Win.Hid;

internal static class HidPPConstants
{
    public const ushort LogitechVid = 0x046D;
    public const ushort BoltPid = 0xC548;
    public static readonly HashSet<ushort> AllReceiverPids = new() { 0xC548, 0xC52B, 0xC532 };

    public const byte ReportShort = 0x10;
    public const byte ReportLong = 0x11;
    public const int MsgShortLen = 7;
    public const int MsgLongLen = 20;
    public const int MaxReadSize = 32;

    public const ushort FeatureRoot = 0x0000;
    public const ushort FeatureDeviceTypeAndName = 0x0005;
    public const ushort FeatureChangeHost = 0x1814;

    public const byte DeviceTypeKeyboard = 0;
    public const byte DeviceTypeMouse = 3;
    public const byte DeviceTypeTrackpad = 4;
    public const byte DeviceTypeTrackball = 5;

    public const byte DevnumberDirect = 0xFF;
    public const byte SwId = 0x0A;
    public const byte ChangeHostFnSet = 0x10;

    public static readonly IReadOnlyDictionary<byte, int> MsgLengths = new Dictionary<byte, int>
    {
        [ReportShort] = MsgShortLen,
        [ReportLong] = MsgLongLen,
    };

    public static readonly HashSet<(ushort Page, ushort Usage)> DirectUsagePairs = new()
    {
        (0xFF00, 0x0002),
        (0xFF43, 0x0202),
        (0xFF0C, 0x0001),
        (0x0001, 0x0006),
        (0x0001, 0x0002),
    };
}
