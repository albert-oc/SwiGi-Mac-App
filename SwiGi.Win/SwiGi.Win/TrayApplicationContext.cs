namespace SwiGi.Win;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private readonly NotifyIcon _trayIcon;
    private readonly SwiGiEngine _engine;
    private readonly ToolStripMenuItem _startStopItem;
    private readonly ToolStripMenuItem _verboseItem;
    private readonly ToolStripMenuItem _statusItem;

    public TrayApplicationContext()
    {
        _engine = new SwiGiEngine();
        _engine.StatusChanged += OnStatusChanged;

        _statusItem = new ToolStripMenuItem("Stopped") { Enabled = false };
        _startStopItem = new ToolStripMenuItem("Start", null, OnStartStop);
        _verboseItem = new ToolStripMenuItem("Verbose logging") { CheckOnClick = true };
        _verboseItem.CheckedChanged += (_, _) => _engine.VerboseLogging = _verboseItem.Checked;

        var menu = new ContextMenuStrip();
        menu.Items.Add(new ToolStripMenuItem("SwiGi") { Enabled = false, Font = new Font(SystemFonts.MenuFont, FontStyle.Bold) });
        menu.Items.Add(_statusItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(_startStopItem);
        menu.Items.Add(_verboseItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(new ToolStripMenuItem("Quit", null, OnQuit));

        _trayIcon = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "SwiGi",
            Visible = true,
            ContextMenuStrip = menu
        };
        _trayIcon.DoubleClick += (_, _) => OnStartStop(null, EventArgs.Empty);
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
            _engine.Dispose();
            _trayIcon.Dispose();
        }
        base.Dispose(disposing);
    }
}
