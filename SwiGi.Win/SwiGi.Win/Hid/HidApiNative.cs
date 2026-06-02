using System.Runtime.InteropServices;

namespace SwiGi.Win.Hid;

internal static class HidApiNative
{
    private const string LibName = "hidapi";

    static HidApiNative()
    {
        NativeLibrary.SetDllImportResolver(typeof(HidApiNative).Assembly, ResolveHidApi);
        hid_init();
    }

    private static IntPtr ResolveHidApi(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (!libraryName.Equals(LibName, StringComparison.OrdinalIgnoreCase))
            return IntPtr.Zero;

        var baseDir = AppContext.BaseDirectory;
        foreach (var name in new[] { "hidapi.dll", "libhidapi-0.dll" })
        {
            var path = Path.Combine(baseDir, name);
            if (File.Exists(path) && NativeLibrary.TryLoad(path, out var handle))
                return handle;
        }

        if (NativeLibrary.TryLoad(LibName, assembly, searchPath, out var systemHandle))
            return systemHandle;

        throw new DllNotFoundException(
            "hidapi.dll not found. Place hidapi.dll next to SwiGi.exe or download from https://github.com/libusb/hidapi/releases");
    }

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int hid_init();

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int hid_exit();

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr hid_enumerate(ushort vendorId, ushort productId);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void hid_free_enumeration(IntPtr devs);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern IntPtr hid_open_path(string path);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void hid_close(IntPtr device);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int hid_write(IntPtr device, byte[] data, nuint length);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int hid_read_timeout(IntPtr device, byte[] data, nuint length, int milliseconds);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr hid_error(IntPtr device);

    public static string GetLastError(IntPtr device = default)
    {
        var ptr = hid_error(device);
        return ptr == IntPtr.Zero ? "unknown hidapi error" : Marshal.PtrToStringUni(ptr) ?? "unknown hidapi error";
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct HidDeviceInfo
    {
        public IntPtr Path;
        public ushort VendorId;
        public ushort ProductId;
        public IntPtr SerialNumber;
        public ushort ReleaseNumber;
        public IntPtr ManufacturerString;
        public IntPtr ProductString;
        public ushort UsagePage;
        public ushort Usage;
        public int InterfaceNumber;
        public IntPtr Next;
    }

    public static string PathToString(IntPtr pathPtr)
    {
        if (pathPtr == IntPtr.Zero) return string.Empty;
        return Marshal.PtrToStringAnsi(pathPtr) ?? string.Empty;
    }
}
