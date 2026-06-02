using System.Buffers.Binary;

namespace SwiGi.Win.Hid;

internal static class HidPPProtocol
{
    private static readonly byte[] PingMessage = BuildPing();

    public static ReadOnlyMemory<byte> Ping => PingMessage;

    private static byte[] BuildPing()
    {
        var requestId = (ushort)((HidPPConstants.FeatureRoot << 8) | HidPPConstants.SwId);
        return BuildMessage(HidPPConstants.DevnumberDirect, requestId, new byte[] { 0, 0, 0 });
    }

    public static byte[] BuildMessage(byte devnumber, ushort requestId, ReadOnlySpan<byte> parameters)
    {
        var data = new byte[20];
        BinaryPrimitives.WriteUInt16BigEndian(data.AsSpan(0, 2), requestId);
        parameters.CopyTo(data.AsSpan(2));

        var msg = new byte[22];
        msg[0] = HidPPConstants.ReportLong;
        msg[1] = devnumber;
        data.CopyTo(msg.AsSpan(2));
        return msg;
    }

    public static byte[] PackParams(params object[] parameters)
    {
        using var ms = new MemoryStream();
        foreach (var param in parameters)
        {
            switch (param)
            {
                case byte b:
                    ms.WriteByte(b);
                    break;
                case int i:
                    ms.WriteByte((byte)(i & 0xFF));
                    break;
                case byte[] bytes:
                    ms.Write(bytes);
                    break;
            }
        }
        return ms.ToArray();
    }

    public static byte[]? HidppRequest(HidTransport transport, byte devnumber, ushort requestId, object[]? parameters = null, int timeoutMs = 500)
    {
        var maskedRequestId = (ushort)((requestId & 0xFFF0) | HidPPConstants.SwId);
        var paramsBytes = parameters is { Length: > 0 } ? PackParams(parameters) : Array.Empty<byte>();
        var requestData = new byte[2 + paramsBytes.Length];
        BinaryPrimitives.WriteUInt16BigEndian(requestData.AsSpan(0, 2), maskedRequestId);
        paramsBytes.CopyTo(requestData.AsSpan(2));
        var message = BuildMessage(devnumber, maskedRequestId, paramsBytes);

        try
        {
            transport.Write(message);
        }
        catch
        {
            return null;
        }

        var deadline = DateTime.UtcNow.AddMilliseconds(timeoutMs);
        while (DateTime.UtcNow < deadline)
        {
            byte[]? raw;
            try
            {
                raw = transport.Read(timeoutMs);
            }
            catch
            {
                return null;
            }

            if (raw is null or { Length: < 4 }) continue;
            if (!HidPPConstants.MsgLengths.TryGetValue(raw[0], out var expectedLen) || raw.Length != expectedLen)
                continue;

            var rdev = raw[1];
            if (rdev != devnumber && rdev != (devnumber ^ 0xFF)) continue;

            var rdata = raw.AsSpan(2);

            if (raw[0] == HidPPConstants.ReportShort && rdata[0] == 0x8F && rdata.Slice(1, 2).SequenceEqual(requestData.AsSpan(0, 2)))
                return null;
            if (rdata[0] == 0xFF && rdata.Slice(1, 2).SequenceEqual(requestData.AsSpan(0, 2)))
                return null;
            if (rdata.Slice(0, 2).SequenceEqual(requestData.AsSpan(0, 2)))
            {
                var payload = new byte[rdata.Length - 2];
                rdata.Slice(2).CopyTo(payload);
                return payload;
            }
        }

        return null;
    }

    public static byte? ResolveFeature(HidTransport transport, byte devnumber, ushort featureCode)
    {
        var requestId = (ushort)((HidPPConstants.FeatureRoot << 8) | 0x00);
        var reply = HidppRequest(transport, devnumber, requestId,
            new object[] { (byte)(featureCode >> 8), (byte)(featureCode & 0xFF), (byte)0 });
        if (reply is null or { Length: 0 } || reply[0] == 0x00) return null;
        return reply[0];
    }

    public static byte? GetDeviceType(HidTransport transport, byte devnumber, byte featureIndex)
    {
        var requestId = (ushort)((featureIndex << 8) | 0x20);
        return HidppRequest(transport, devnumber, requestId)?.FirstOrDefault();
    }

    public static string? GetDeviceName(HidTransport transport, byte devnumber, byte featureIndex)
    {
        var baseRequestId = (ushort)((featureIndex << 8) | 0x00);
        var reply = HidppRequest(transport, devnumber, baseRequestId);
        if (reply is null or { Length: 0 }) return null;

        var nameLen = reply[0];
        if (nameLen == 0) return null;

        var chars = new List<byte>();
        while (chars.Count < nameLen)
        {
            var chunkRequestId = (ushort)((featureIndex << 8) | 0x10);
            var chunk = HidppRequest(transport, devnumber, chunkRequestId, new object[] { (byte)chars.Count });
            if (chunk is null) break;
            chars.AddRange(chunk.Take(nameLen - chars.Count));
        }

        return chars.Count > 0 ? System.Text.Encoding.UTF8.GetString(chars.ToArray()) : null;
    }

    public static void SendChangeHost(HidTransport transport, byte devnumber, byte featureIndex, byte targetHost)
    {
        var requestId = (ushort)((featureIndex << 8) | (HidPPConstants.ChangeHostFnSet & 0xF0) | HidPPConstants.SwId);
        var message = BuildMessage(devnumber, requestId, new[] { targetHost });
        transport.Write(message);
    }
}
