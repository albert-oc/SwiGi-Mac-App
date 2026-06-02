using SwiGi.Win.Hid;

namespace SwiGi.Win;

internal enum EngineStatusKind
{
    Stopped,
    Starting,
    Running,
    Error
}

internal sealed class EngineStatus
{
    public EngineStatusKind Kind { get; init; } = EngineStatusKind.Stopped;
    public string? Keyboard { get; init; }
    public string? Mouse { get; init; }
    public int SwitchCount { get; init; }
    public string? ErrorMessage { get; init; }
}

internal sealed class SwiGiEngine : IDisposable
{
    private readonly object _lock = new();
    private CancellationTokenSource? _cts;
    private Task? _worker;
    private EngineStatus _status = new();

    public event Action<EngineStatus>? StatusChanged;
    public bool VerboseLogging { get; set; }

    public EngineStatus Status
    {
        get { lock (_lock) return _status; }
    }

    public bool IsRunning
    {
        get
        {
            var k = Status.Kind;
            return k is EngineStatusKind.Running or EngineStatusKind.Starting;
        }
    }

    public void Start()
    {
        lock (_lock)
        {
            if (_cts is not null) return;
            _cts = new CancellationTokenSource();
            SetStatus(new EngineStatus { Kind = EngineStatusKind.Starting });
            _worker = Task.Run(() => RunLoopAsync(_cts.Token));
        }
    }

    public void Stop()
    {
        lock (_lock)
        {
            _cts?.Cancel();
            _cts = null;
        }
    }

    public void Dispose()
    {
        Stop();
        try { _worker?.Wait(TimeSpan.FromSeconds(3)); } catch { /* ignore */ }
    }

    private void SetStatus(EngineStatus status)
    {
        lock (_lock) _status = status;
        StatusChanged?.Invoke(status);
    }

    private void Log(string message, bool force = false)
    {
        if (VerboseLogging || force)
            System.Diagnostics.Debug.WriteLine($"[SwiGi] {message}");
    }

    private async Task RunLoopAsync(CancellationToken ct)
    {
        Log("Searching for devices...", force: true);

        DeviceInfo? keyboard;
        DeviceInfo? mouse = null;
        if (keyboard is null)
        {
            SetStatus(new EngineStatus { Kind = EngineStatusKind.Error, ErrorMessage = "Keyboard not found. Check Bluetooth connection." });
            CleanupWorker();
            return;
        }

        mouse = DeviceDiscovery.FindDevice(HidPPConstants.DeviceTypeMouse);
        if (mouse is null)
        {
            keyboard.Dispose();
            SetStatus(new EngineStatus { Kind = EngineStatusKind.Error, ErrorMessage = "Mouse not found. Check Bluetooth connection." });
            CleanupWorker();
            return;
        }

        Log($"Keyboard: {keyboard.Name} (CHANGE_HOST idx={keyboard.ChangeHostIndex})", force: true);
        Log($"Mouse: {mouse.Name} (CHANGE_HOST idx={mouse.ChangeHostIndex})", force: true);

        var totalSwitches = 0;
        var lastResponse = DateTime.UtcNow;
        const int watchdogSeconds = 10;

        SetStatus(new EngineStatus
        {
            Kind = EngineStatusKind.Running,
            Keyboard = keyboard.Name,
            Mouse = mouse.Name,
            SwitchCount = totalSwitches
        });

        try
        {
            while (!ct.IsCancellationRequested)
            {
                if ((DateTime.UtcNow - lastResponse).TotalSeconds > watchdogSeconds)
                {
                    Log($"Watchdog: no response for {watchdogSeconds}s, reconnecting...", force: true);
                    keyboard.Dispose();
                    mouse.Dispose();
                    await Task.Delay(1000, ct);

                    var kb = DeviceDiscovery.FindDevice(HidPPConstants.DeviceTypeKeyboard);
                    if (kb is not null)
                    {
                        keyboard = kb;
                        Log($"Watchdog reconnect: {keyboard.Name}", force: true);
                    }

                    lastResponse = DateTime.UtcNow;
                    continue;
                }

                try
                {
                    keyboard.Transport.Write(HidPPProtocol.Ping.Span);
                }
                catch
                {
                    Log("Keyboard disconnected, waiting for reconnect...", force: true);
                    keyboard.Dispose();

                    DeviceInfo? kbNew = null;
                    for (var attempt = 0; attempt < 120 && !ct.IsCancellationRequested; attempt++)
                    {
                        await Task.Delay(500, ct);
                        kbNew = DeviceDiscovery.FindDevice(HidPPConstants.DeviceTypeKeyboard);
                        if (kbNew is not null) break;
                    }

                    if (kbNew is null)
                    {
                        Log("Keyboard did not return, retrying...", force: true);
                        continue;
                    }

                    keyboard = kbNew;
                    Log($"Keyboard reconnect: {keyboard.Name}", force: true);
                    lastResponse = DateTime.UtcNow;
                    mouse.Dispose();
                    mouse = null;
                    continue;
                }

                var deadline = DateTime.UtcNow.AddMilliseconds(80);
                while (DateTime.UtcNow < deadline && !ct.IsCancellationRequested)
                {
                    byte[]? raw;
                    try
                    {
                        raw = keyboard.Transport.Read(25);
                    }
                    catch
                    {
                        break;
                    }

                    if (raw is null or { Length: < 4 }) continue;
                    if (!HidPPConstants.MsgLengths.TryGetValue(raw[0], out var expectedLen) || raw.Length != expectedLen)
                        continue;

                    var feature = raw[2];
                    var function = raw[3];
                    var swId = (byte)(function & 0x0F);
                    lastResponse = DateTime.UtcNow;

                    if (feature == keyboard.ChangeHostIndex && swId == 0 && raw.Length > 5)
                    {
                        var targetHost = raw[5];
                        Log($"Easy-Switch: {keyboard.Name} → host {targetHost}", force: true);

                        if (mouse is null || !mouse.Transport.IsOpen)
                        {
                            var newMouse = DeviceDiscovery.FindDevice(HidPPConstants.DeviceTypeMouse);
                            if (newMouse is not null)
                                mouse = newMouse;
                            else
                            {
                                Log("Mouse unavailable — will switch on next Easy-Switch", force: true);
                                break;
                            }
                        }

                        try
                        {
                            HidPPProtocol.SendChangeHost(mouse.Transport, HidPPConstants.DevnumberDirect,
                                mouse.ChangeHostIndex, targetHost);
                            totalSwitches++;
                            Log($"CHANGE_HOST → {mouse.Name} → host {targetHost}", force: true);
                            SetStatus(new EngineStatus
                            {
                                Kind = EngineStatusKind.Running,
                                Keyboard = keyboard.Name,
                                Mouse = mouse.Name,
                                SwitchCount = totalSwitches
                            });
                        }
                        catch
                        {
                            Log("CHANGE_HOST to mouse failed, reconnecting mouse...", force: true);
                            mouse.Dispose();
                            await Task.Delay(1000, ct);
                            var newMouse = DeviceDiscovery.FindDevice(HidPPConstants.DeviceTypeMouse);
                            if (newMouse is not null)
                            {
                                mouse = newMouse;
                                try
                                {
                                    HidPPProtocol.SendChangeHost(mouse.Transport, HidPPConstants.DevnumberDirect,
                                        mouse.ChangeHostIndex, targetHost);
                                    totalSwitches++;
                                    Log($"CHANGE_HOST → {mouse.Name} → host {targetHost} (after reconnect)", force: true);
                                    SetStatus(new EngineStatus
                                    {
                                        Kind = EngineStatusKind.Running,
                                        Keyboard = keyboard.Name,
                                        Mouse = mouse.Name,
                                        SwitchCount = totalSwitches
                                    });
                                }
                                catch
                                {
                                    Log("CHANGE_HOST retry failed", force: true);
                                }
                            }
                        }

                        break;
                    }

                    if (swId == 0)
                        Log($"Notification: feat=0x{feature:X2}");
                }

                await Task.Delay(20, ct);
            }
        }
        catch (OperationCanceledException)
        {
            // normal shutdown
        }
        finally
        {
            keyboard.Dispose();
            mouse?.Dispose();
            SetStatus(new EngineStatus { Kind = EngineStatusKind.Stopped });
            CleanupWorker();
        }
    }

    private void CleanupWorker()
    {
        lock (_lock)
        {
            _cts?.Dispose();
            _cts = null;
            _worker = null;
        }
    }
}
