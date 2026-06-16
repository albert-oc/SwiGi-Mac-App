using System.Text.Json;

namespace SwiGi.Win;

internal sealed class AppSettingsData
{
    public bool LaunchAtLogin { get; set; }
}

internal static class AppSettings
{
    private static readonly string SettingsDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "SwiGi");
    private static readonly string SettingsPath = Path.Combine(SettingsDir, "settings.json");

    public static bool LaunchAtLogin
    {
        get => Load().LaunchAtLogin;
        set
        {
            var data = Load();
            data.LaunchAtLogin = value;
            Save(data);
            StartupManager.SetEnabled(value);
        }
    }

    public static void ApplyStoredPreferences()
    {
        StartupManager.SetEnabled(LaunchAtLogin);
    }

    private static AppSettingsData Load()
    {
        try
        {
            if (!File.Exists(SettingsPath))
                return new AppSettingsData();
            var json = File.ReadAllText(SettingsPath);
            return JsonSerializer.Deserialize<AppSettingsData>(json) ?? new AppSettingsData();
        }
        catch
        {
            return new AppSettingsData();
        }
    }

    private static void Save(AppSettingsData data)
    {
        try
        {
            Directory.CreateDirectory(SettingsDir);
            var json = JsonSerializer.Serialize(data);
            File.WriteAllText(SettingsPath, json);
        }
        catch
        {
            // Ignore persistence errors; in-memory preference still applies this session.
        }
    }
}
