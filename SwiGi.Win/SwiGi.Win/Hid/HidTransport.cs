namespace SwiGi.Win.Hid;

internal sealed class HidTransport : IDisposable
{
    private IntPtr _device;
    public string Path { get; }
    public ushort Pid { get; }

    public HidTransport(string path, ushort pid)
    {
        Path = path;
        Pid = pid;
        _device = HidApiNative.hid_open_path(path);
        if (_device == IntPtr.Zero)
            throw new IOException($"hid_open_path failed: {HidApiNative.GetLastError()}");
    }

    public bool IsOpen => _device != IntPtr.Zero;

    public byte[]? Read(int timeoutMs = 500)
    {
        if (_device == IntPtr.Zero)
            throw new InvalidOperationException("Transport is closed");

        var buffer = new byte[HidPPConstants.MaxReadSize];
        var count = HidApiNative.hid_read_timeout(_device, buffer, (nuint)buffer.Length, timeoutMs);
        if (count < 0)
        {
            var err = HidApiNative.GetLastError(_device);
            if (err.Contains("success", StringComparison.OrdinalIgnoreCase) || string.IsNullOrEmpty(err))
                return null;
            throw new IOException($"HID read failed: {err}");
        }

        if (count == 0) return null;
        var result = new byte[count];
        Array.Copy(buffer, result, count);
        return result;
    }

    public void Write(ReadOnlySpan<byte> message)
    {
        if (_device == IntPtr.Zero)
            throw new InvalidOperationException("Transport is closed");

        var arr = message.ToArray();
        var count = HidApiNative.hid_write(_device, arr, (nuint)arr.Length);
        if (count < 0)
            throw new IOException($"HID write failed: {HidApiNative.GetLastError(_device)}");
    }

    public void Dispose()
    {
        if (_device != IntPtr.Zero)
        {
            HidApiNative.hid_close(_device);
            _device = IntPtr.Zero;
        }
    }
}
