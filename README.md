# metric-widget

Lightweight macOS desktop glass panels for live network, memory, CPU, RAM, and storage metrics.

Menu-bar app (no Dock icon). Toggle each panel, drag them on the desktop, optionally open at login.

## Run

```bash
swift build -c debug --product MetricsWidget
```

Then launch the signed app bundle at `build/MetricsWidget.app` (or open the Xcode project). Requires macOS 15+.
