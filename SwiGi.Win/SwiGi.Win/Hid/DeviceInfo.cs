namespace SwiGi.Win.Hid;

internal sealed class DeviceInfo : IDisposable
{
    public HidTransport Transport { get; }
    public string Name { get; }
    public ushort Pid { get; }
    public byte ChangeHostIndex { get; }

    public DeviceInfo(HidTransport transport, string name, ushort pid, byte changeHostIndex)
    {
        Transport = transport;
        Name = name;
        Pid = pid;
        ChangeHostIndex = changeHostIndex;
    }

    public void Dispose() => Transport.Dispose();
}
