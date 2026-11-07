# Status

A Mac app that lives in the menu bar and reads the machine quietly. Click the icon at the top for the processor, memory, network, and battery. Open the board when you want the full picture. Pin it to the desktop as a widget, in four sizes.

The numbers stay on your Mac. Nothing is sent to a server, and there is no account.

<p align="center">
  <a href="./README.md"><img alt="English" src="https://img.shields.io/badge/English-174F46?style=for-the-badge"></a>
  <a href="./docs/i18n/README.ar.md"><img alt="Arabic" src="https://img.shields.io/badge/%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./docs/i18n/README.fr.md"><img alt="French" src="https://img.shields.io/badge/Fran%C3%A7ais-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./docs/i18n/README.es.md"><img alt="Spanish" src="https://img.shields.io/badge/Espa%C3%B1ol-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./docs/i18n/README.de.md"><img alt="German" src="https://img.shields.io/badge/Deutsch-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./docs/i18n/README.tr.md"><img alt="Turkish" src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
</p>

## Download

No Xcode, and no terminal.

1. Download [Status.zip](https://github.com/0xx9/Status/releases/latest/download/Status.zip).
2. Double-click the zip. A **Status** app comes out.
3. Drag **Status** into **Applications**.
4. The first time, Control-click **Status** and choose **Open**, then **Open** again. macOS asks once, because this copy is not from the App Store.

After that it lives in the menu bar. Click the icon.

<p align="center">
  <img src="docs/screenshots/dashboard-light.png" alt="The Status board in light appearance" width="920">
</p>

## What you see

The board is not a list of figures. Each instrument has a face: a ring, a trace, and a state.

- **Processor.** The current share, user time and system time, performance cores and efficiency cores, and the load over one, five, and fifteen minutes. A graphics reading appears beside it when the machine reports one.
- **Memory.** Apps, wired, compressed, and cached, with pressure, swap, and what is still free.
- **Network.** Download and upload on the real interface, with the address and a trace. Internal system interfaces are left out.
- **Battery.** Charge or time remaining, cycle count, and temperature when the hardware provides it.
- **Disks.** Read and write rates, and how full each volume is.
- **Processes.** What is heaviest right now, with search, sorted by processor or memory.
- **The machine.** Chip, system, uptime, and thermal state.

One line above the board says what deserves attention: calm, busy, under strain, hot, or low battery.

<p align="center">
  <img src="docs/screenshots/dashboard-dark.png" alt="The Status board in dark appearance" width="920">
</p>

## Menu bar

A left click opens the small panel. A right click opens the menu: pause monitoring, refresh, details, settings, and quit.

Choose what sits next to the icon: processor, memory, network, or battery, up to three at once. A single metric draws a small trace instead of a number.

Monitoring runs on its own. You can pause it, or keep it gentler on battery and in Low Power Mode. The pace is one second, two seconds, or five.

A notification arrives when the processor, memory, or heat crosses the limit you set. The first moments after launch stay quiet, so the app does not announce itself while it is waking up.

Launch at login is in Settings. A locally signed build may ask macOS for approval once, in System Settings.

## Widgets

Four sizes: small, medium, large, and extra large. The same board: a processor ring, memory, network, battery, and a trace of recent readings. The clock on the face is the time of the last reading. When it moves, the numbers are new.

The widget reads the state the app writes, so it matches the menu bar instead of taking a thin sample of its own. If the app is not running, it samples for itself.

<p align="center">
  <img src="docs/screenshots/widget-small-light.png" alt="Small Status widget" width="220">
  &nbsp;&nbsp;
  <img src="docs/screenshots/widget-medium-light.png" alt="Medium Status widget" width="460">
</p>

<p align="center">
  <img src="docs/screenshots/widget-large-light.png" alt="Large Status widget" width="420">
  &nbsp;&nbsp;
  <img src="docs/screenshots/widget-extra-light.png" alt="Extra large Status widget" width="640">
</p>

After you install a new build, remove the old Status widget from the desktop and add it again. macOS keeps a widget tied to the app copy it was added from.

## Language

The app follows the system language. In Arabic, the layout runs right to left and the figures stay in place. Settings switches between Arabic and English whenever you want.

The pages of this repository are separate. The buttons at the top open the same explanation in Arabic, French, Spanish, German, and Turkish.

## Build

Only if you want to compile it yourself. The download above is the app. macOS 15 and Xcode 16 or later.

```bash
git clone https://github.com/0xx9/Status.git
cd Status
xcodebuild -project Status.xcodeproj -scheme Status -destination 'platform=macOS' -configuration Release build
open ~/Library/Developer/Xcode/DerivedData/Status-*/Build/Products/Release/Status.app
```

Or open `Status.xcodeproj` and run it.

The app itself is not sandboxed, because processes, disks, and the network need that. The widget extension is sandboxed, and it reads the state file the app writes into the widget container.

## Inside the project

| Folder | What it holds |
| --- | --- |
| `Status` | Menu bar, board, settings, and alerts |
| `StatusWidgets` | The macOS widget |
| `Shared` | Sampling, math, formatting, and copy |
| `StatusTests` | Math, formatting, and a live sample from the machine |
| `tools` | The app icon drawing |

Version 1.0. Bundle identifier `com.muhsan.status`.
