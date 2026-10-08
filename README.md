# metric-widget
Lightweight macOS desktop glass panels for live network, memory, CPU, RAM, and storage metrics.

**Clock tiles**\
You can configure as many clocks for as many timezones as you would like.\
<img width="383" height="592" alt="MetricsWidget-all" src="https://github.com/user-attachments/assets/61fde2fc-1597-4564-97d3-f0f1f28b98d4" />

**Network, App memory, Agent usage, and Computer stats**\
Each tile can be moved independently. They snap to each other and the edges of the desktop.\
<img width="1936" height="713" alt="MetricsWidget-readme-blurred" src="https://github.com/user-attachments/assets/478f87d4-bdaa-4e22-82c9-1cf6e0836bb3" />

Metric Widget has probably the worse name that I've ever come up with for an app, but it's actually pretty cool. No dock icon or presence; the app is fully controlled by the menu bar icon. Each tile can be toggled independently, drag them wherever you want on the desktop, and set the app to open at login, if you'd like.

I built this because I miss my Gnome desktop. I like borderless windows with no titlebar.

**Clock** — **world-clock** desktop tiles (7-segment LED, zone label, AM/PM + red PM indicator). Enable zones in **Settings → World clocks**.

**Usage** - If you use Cursor, Grok Bot, OpenAI, or Claude, you can enter an API key in **Settings → Keys** to configure usage stats. Grows/shrinks with provider content when you have not manually resized it

**Panel sizing** — drag any panel edge/corner to resize (click the panel first so it becomes focused). 


## Install

Download the latest zip from [Releases](https://github.com/LeTanque/metric-widget/releases/latest), unzip it, and move `MetricsWidget.app` to `/Applications`.

The first open is blocked because the app is not notarized. Right-click the app and choose **Open**, allow it in System Settings → Privacy & Security, or run:

```bash
xattr -dr com.apple.quarantine /Applications/MetricsWidget.app
```

Build from source on macOS 15 with Command Line Tools:

```bash
./scripts/package_app.sh
```

Then copy `build/MetricsWidget.app` to `/Applications`.

## Run

Release build:

```bash
./build.sh
ditto build/MetricsWidget.app /Applications/MetricsWidget.app
open /Applications/MetricsWidget.app
```

Debug iteration:

```bash
swift build -c debug --product MetricsWidget
```

Then launch the signed app bundle at `build/MetricsWidget.app` (or open the Xcode project). Requires macOS 15+.

## Usage tile

Menu bar → **Usage** and **Settings…**. Enable Cursor, Grok Bot, and/or OpenAI (Anthropic is optional).

It's designed to work off of a keychain stored key for Anthropic and OpenAI. If you would like to put your key in the settings menu, that works too. Cursor and Grok Bot are unofficial integrations, so they might be flaky. So far, for me, they work fine. But in the future, this could break and I'll have to update the app.

- **Cursor** reads the signed-in session from `state.vscdb` (sign in to Cursor on this Mac; no extra key). Two unofficial APIs, same billing period:
  - `GetCurrentPeriodUsage` — **dollar** included spend / remaining (bar = remaining included $; “beyond included” for overage).
  - `GET cursor.com/api/usage-summary` — **Cursor Models** and **Other Models** percent-used bars (dashboard semantics). Cookie auth via `WorkosCursorSessionToken` derived from the IDE token. Falls back to `autoPercentUsed` / `apiPercentUsed` on `GetCurrentPeriodUsage` if the summary call fails.
- **Grok Bot** uses the same Cursor session token and calls the unofficial `GetSandUsageStatus` endpoint. It tracks the **weekly** Grok Bot included pool (`usagePercent` is used share; the bar shows remaining). That meter is separate from Cursor’s monthly plan bar; after weekly Grok runs out, usage may spill to shared Cursor on-demand (not shown on this tile). Accounts with no Sand allowance show a placeholder instead of a bar.
- **OpenAI / Anthropic** keys are generic Keychain passwords (`service` `com.metricswidget.app`, accounts `openai.admin` and `anthropic.admin`). OpenAI needs an **Admin** key with `api.usage.read`. Anthropic needs `sk-ant-admin…`.

Equivalent CLI:

```bash
security add-generic-password -s com.metricswidget.app -a openai.admin -w
```

Usage refreshes about every 10 minutes.

## Build plan

Native macOS widgets are Swift + SwiftUI (WidgetKit). That is not what this project is. WidgetKit is a snapshot renderer (~40–70 reloads/day). A network graph, CPU bar, and top-memory list need a tiny always-running app, the same pattern as Stats / iStat Menus.

This is a signed local macOS app (`MetricsWidget`) with a menu-bar extra and three borderless, draggable desktop panels. Visual language: system fonts, SF Symbols, semantic colors, and Tahoe glass (`NSGlassEffectView` on macOS 26, `NSVisualEffectView` fallback) so they sit next to the Clock widget without copying Apple’s private widget chrome.

Greenfield Xcode / SwiftPM macOS app (Swift 6, SwiftUI + a thin AppKit window layer). No App Sandbox: enumerating other processes’ RSS is blocked in the sandbox, and this is a local system monitor.

```mermaid
flowchart LR
  Sampler["Sampler 1Hz"] --> Store["MetricsStore"]
  Store --> NetUI["Network panel"]
  Store --> MemUI["Apps memory panel"]
  Store --> SysUI["CPU RAM Disk panel"]
  MenuBar["Menu bar extra"] --> Panels["Show hide persist frames"]
```

### App shell

- Xcode target: macOS app, menu-bar only (`LSUIElement` / `MenuBarExtra` so no Dock icon).
- Menu: toggle each panel, “Open at Login” via `SMAppService`, Quit.
- Three `NSPanel`s: borderless, transparent, movable-by-background, join all Spaces, level just above the desktop (visible over wallpaper, under normal windows unless we later add a “float on top” toggle). Persist origin per panel in `UserDefaults`.
- Glass: host SwiftUI in an AppKit visual-effect / glass content view. Content itself stays transparent; do not paint an opaque card.

### Lightweight sampler

One process, one timer (~1s), Mach/BSD APIs only — never `top`/`ps`/`ifconfig`. See [`MetricsWidget/Metrics/Sampler.swift`](MetricsWidget/Metrics/Sampler.swift) and friends.

- **CPU (gross):** `host_statistics` / `host_cpu_load_info` tick deltas → single percent.
- **RAM:** `host_statistics64` (`free` / `active` / `inactive` / `wired` / `compressed`) → used percent vs physical memory (`sysctl hw.memsize`).
- **Disk:** `statfs("/")` → used / free for a two-slice pie (Used / Free). Optional label with GB.
- **Network:** `getifaddrs` + `ifi_ibytes` / `ifi_obytes` deltas on the default-route interface (typically `en0`). Keep ~60 samples for up/down sparklines. Show interface name and IPv4. **Public IP:** one HTTPS lookup (e.g. `https://api.ipify.org`), cached 10–15 minutes, shown as “—” if offline. No per-second WAN polling.
- **Top memory apps:** `proc_listpids` + `proc_pidinfo(PROC_PIDTASKINFO)` for RSS; resolve names via `proc_name` / `NSRunningApplication`. Show top ~5–8. Keep `kernel_task` labeled so the snapshot matches Activity Monitor.

Pause the timer when all panels are hidden.

### Three panel UIs (Swift Charts + compact layout)

Fixed widget-like sizes (not free-resize), SF Pro, secondary labels at `.caption` / `.monospacedDigit()`.

1. **Network** — dual sparkline (up / down, distinct system-tint colors), current rates, interface (`en0`, etc.), LAN IP, WAN IP.
2. **App memory** — snapshot list: app name + RSS, plus a one-line total process memory if cheap. No per-process graphs.
3. **System** — storage pie (Used vs Free); CPU bar with percent overlay; RAM bar with percent overlay. Same bar treatment for both.

Swift Charts for pie + sparkline; custom `Canvas`/`ProgressView` style for the bars so the percent sits in/on the bar cleanly.

### Layout

- [`MetricsWidget.xcodeproj`](MetricsWidget.xcodeproj) + app target, Info.plist (`LSUIElement`), entitlements (no sandbox; outgoing network client for WAN IP).
- [`MetricsWidget/App/MetricsWidgetApp.swift`](MetricsWidget/App/MetricsWidgetApp.swift) — `MenuBarExtra`, panel lifecycle.
- [`MetricsWidget/App/GlassPanelWindow.swift`](MetricsWidget/App/GlassPanelWindow.swift) — AppKit panel + glass host.
- [`MetricsWidget/Metrics/Sampler.swift`](MetricsWidget/Metrics/Sampler.swift), [`CPU.swift`](MetricsWidget/Metrics/CPU.swift), [`Memory.swift`](MetricsWidget/Metrics/Memory.swift), [`Network.swift`](MetricsWidget/Metrics/Network.swift), [`Disk.swift`](MetricsWidget/Metrics/Disk.swift), [`Processes.swift`](MetricsWidget/Metrics/Processes.swift).
- [`NetworkPanelView.swift`](MetricsWidget/Views/NetworkPanelView.swift), [`AppMemoryPanelView.swift`](MetricsWidget/Views/AppMemoryPanelView.swift), [`SystemPanelView.swift`](MetricsWidget/Views/SystemPanelView.swift).
