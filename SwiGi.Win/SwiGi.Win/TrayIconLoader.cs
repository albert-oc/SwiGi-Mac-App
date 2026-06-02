namespace SwiGi.Win;

internal static class TrayIconLoader
{
    private const string EmbeddedResourceName = "SwiGi.Win.app.ico";

    public static Icon Load()
    {
        var fromResource = LoadEmbedded();
        if (fromResource is not null)
            return fromResource;

        var fromExe = LoadFromExecutable();
        if (fromExe is not null)
            return fromExe;

        var fromFile = LoadFromFile();
        if (fromFile is not null)
            return fromFile;

        return SystemIcons.Application;
    }

    private static Icon? LoadEmbedded()
    {
        try
        {
            var assembly = typeof(TrayIconLoader).Assembly;
            using var stream = assembly.GetManifestResourceStream(EmbeddedResourceName);
            if (stream is null)
                return null;
            return new Icon(stream);
        }
        catch
        {
            return null;
        }
    }

    private static Icon? LoadFromExecutable()
    {
        try
        {
            var path = Application.ExecutablePath;
            if (string.IsNullOrEmpty(path))
                return null;
            return Icon.ExtractAssociatedIcon(path);
        }
        catch
        {
            return null;
        }
    }

    private static Icon? LoadFromFile()
    {
        try
        {
            var path = Path.Combine(AppContext.BaseDirectory, "app.ico");
            if (!File.Exists(path))
                return null;
            // Prefer 32x32 for tray clarity; fall back to default frame.
            return new Icon(path, new Size(32, 32));
        }
        catch
        {
            try
            {
                var path = Path.Combine(AppContext.BaseDirectory, "app.ico");
                return File.Exists(path) ? new Icon(path) : null;
            }
            catch
            {
                return null;
            }
        }
    }
}
