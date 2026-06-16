namespace SwiGi.Win;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private readonly NotifyIcon _trayIcon;
    private readonly SwiGiEngine _engine;
    private readonly ToolStripMenuItem _startStopItem;
    private readonly ToolStripMenuItem _verboseItem;
    private readonly ToolStripMenuItem _launchAtLoginItem;
    private readonly ToolStripMenuItem _statusItem;

    public TrayApplicationContext()
    {
        AppSettings.ApplyStoredPreferences();

        _engine = new SwiGiEngine();
        _engine.StatusChanged += OnStatusChanged;
        _engine.LogEmitted += OnLogEmitted;

        _statusItem = new ToolStripMenuItem("Stopped") { Enabled = false };
        _startStopItem = new ToolStripMenuItem("Start", null, OnStartStop);
        _verboseItem = new ToolStripMenuItem("Verbose logging") { CheckOnClick = true };
        _verboseItem.CheckedChanged += (_, _) => _engine.VerboseLogging = _verboseItem.Checked;
        _launchAtLoginItem = new ToolStripMenuItem("Start at login") { CheckOnClick = true };
        _launchAtLoginItem.Checked = AppSettings.LaunchAtLogin;
        _launchAtLoginItem.CheckedChanged += (_, _) => AppSettings.LaunchAtLogin = _launchAtLoginItem.Checked;

        var menu = new ContextMenuStrip();
        menu.Items.Add(new ToolStripMenuItem("SwiGi") { Enabled = false, Font = new Font(SystemFonts.MenuFont, FontStyle.Bold) });
        menu.Items.Add(_statusItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(_startStopItem);
        menu.Items.Add(_verboseItem);
        menu.Items.Add(_launchAtLoginItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(new ToolStripMenuItem("Quit", null, OnQuit));

        var trayIcon = TrayIconLoader.Load();
        _trayIcon = new NotifyIcon
        {
            Icon = trayIcon,
            Text = "SwiGi",
            Visible = true,
            ContextMenuStrip = menu
        };
        _trayIcon.DoubleClick += (_, _) => OnStartStop(null, EventArgs.Empty);
    }

    private void OnLogEmitted(string message)
    {
        if (_trayIcon.ContextMenuStrip?.InvokeRequired == true)
        {
            _trayIcon.ContextMenuStrip.BeginInvoke(() => ShowLogBalloon(message));
            return;
        }
        ShowLogBalloon(message);
    }

    private void ShowLogBalloon(string message)
    {
        var text = message.Length > 255 ? message[..252] + "..." : message;
        _trayIcon.BalloonTipTitle = "SwiGi";
        _trayIcon.BalloonTipText = text;
        _trayIcon.BalloonTipIcon = ToolTipIcon.Info;
        _trayIcon.ShowBalloonTip(3000);
    }

    private void OnStatusChanged(EngineStatus status)
    {
        if (_trayIcon.ContextMenuStrip?.InvokeRequired == true)
        {
            _trayIcon.ContextMenuStrip.BeginInvoke(UpdateUi);
            return;
        }
        UpdateUi();

        void UpdateUi()
        {
            _startStopItem.Text = _engine.IsRunning ? "Stop" : "Start";
            _verboseItem.Enabled = !_engine.IsRunning;

            switch (status.Kind)
            {
                case EngineStatusKind.Running:
                    _statusItem.Text = $"Running — {status.SwitchCount} switches";
                    _trayIcon.Text = $"SwiGi — {status.SwitchCount} switches";
                    break;
                case EngineStatusKind.Starting:
                    _statusItem.Text = "Starting…";
                    _trayIcon.Text = "SwiGi — starting";
                    break;
                case EngineStatusKind.Error:
                    _statusItem.Text = status.ErrorMessage ?? "Error";
                    _trayIcon.Text = "SwiGi — error";
                    break;
                default:
                    _statusItem.Text = "Stopped";
                    _trayIcon.Text = "SwiGi";
                    break;
            }
        }
    }

    private void OnStartStop(object? sender, EventArgs e)
    {
        if (_engine.IsRunning)
            _engine.Stop();
        else
            _engine.Start();
    }

    private void OnQuit(object? sender, EventArgs e)
    {
        _engine.Dispose();
        _trayIcon.Visible = false;
        _trayIcon.Dispose();
        Application.Exit();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _engine.LogEmitted -= OnLogEmitted;
            _engine.Dispose();
            _trayIcon.Dispose();
        }
        base.Dispose(disposing);
    }
}
