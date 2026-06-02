using System.Runtime.InteropServices;

namespace SwiGi.Win.Hid;

internal static class DeviceDiscovery
{
    public static DeviceInfo? FindDevice(byte wantedType)
    {
        var head = HidApiNative.hid_enumerate(HidPPConstants.LogitechVid, 0);
        if (head == IntPtr.Zero) return null;

        var candidates = new List<(int Score, string Path, ushort Pid, ushort UsagePage, ushort Usage)>();

        try
        {
            var node = head;
            while (node != IntPtr.Zero)
            {
                var info = Marshal.PtrToStructure<HidApiNative.HidDeviceInfo>(node);
                node = info.Next;

                var pid = info.ProductId;
                var usagePage = info.UsagePage;
                var usage = info.Usage;

                if (HidPPConstants.AllReceiverPids.Contains(pid)) continue;
                if (!HidPPConstants.DirectUsagePairs.Contains((usagePage, usage))) continue;

                var score = usagePage is 0xFF00 or 0xFF43 or 0xFF0C ? 100 : 0;
                var path = HidApiNative.PathToString(info.Path);
                if (string.IsNullOrEmpty(path)) continue;

                candidates.Add((score, path, pid, usagePage, usage));
            }
        }
        finally
        {
            HidApiNative.hid_free_enumeration(head);
        }

        candidates.Sort((a, b) => b.Score.CompareTo(a.Score));

        var foundPids = new HashSet<ushort>();
        foreach (var (_, path, pid, _, _) in candidates)
        {
            if (foundPids.Contains(pid)) continue;

            HidTransport? transport = null;
            try
            {
                transport = new HidTransport(path, pid);

                var featureIndex = HidPPProtocol.ResolveFeature(transport, HidPPConstants.DevnumberDirect, HidPPConstants.FeatureDeviceTypeAndName);
                if (featureIndex is null)
                {
                    transport.Dispose();
                    continue;
                }

                var deviceType = HidPPProtocol.GetDeviceType(transport, HidPPConstants.DevnumberDirect, featureIndex.Value);
                if (deviceType is null)
                {
                    transport.Dispose();
                    continue;
                }

                var name = HidPPProtocol.GetDeviceName(transport, HidPPConstants.DevnumberDirect, featureIndex.Value)
                    ?? $"Logitech-0x{pid:X4}";

                var isMouse = deviceType is HidPPConstants.DeviceTypeMouse
                    or HidPPConstants.DeviceTypeTrackpad
                    or HidPPConstants.DeviceTypeTrackball;

                if (wantedType == HidPPConstants.DeviceTypeKeyboard && deviceType != HidPPConstants.DeviceTypeKeyboard)
                {
                    transport.Dispose();
                    continue;
                }

                if (wantedType == HidPPConstants.DeviceTypeMouse && !isMouse)
                {
                    transport.Dispose();
                    continue;
                }

                var changeHostIndex = HidPPProtocol.ResolveFeature(transport, HidPPConstants.DevnumberDirect, HidPPConstants.FeatureChangeHost);
                if (changeHostIndex is null)
                {
                    transport.Dispose();
                    continue;
                }

                foundPids.Add(pid);
                return new DeviceInfo(transport, name, pid, changeHostIndex.Value);
            }
            catch
            {
                transport?.Dispose();
            }
        }

        return null;
    }
}
