import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var monitor: Monitor
    @EnvironmentObject private var settings: SettingsStore

    private var l10n: L10n { settings.l10n }

    var body: some View {
        Form {
            Section(l10n.t(.general)) {
                Picker(l10n.t(.monitoring), selection: monitoringBinding) {
                    Text(l10n.t(.live)).tag(true)
                    Text(l10n.t(.manual)).tag(false)
                }
                .pickerStyle(.segmented)
                Text(settings.settings.monitoringEnabled ? l10n.t(.liveHint) : l10n.t(.manualHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker(l10n.t(.pace), selection: paceBinding) {
                    Text(l10n.t(.paceLive)).tag(RefreshPace.live)
                    Text(l10n.t(.paceBalanced)).tag(RefreshPace.balanced)
                    Text(l10n.t(.paceQuiet)).tag(RefreshPace.quiet)
                }
                Toggle(l10n.t(.gentleBattery), isOn: binding(\.gentleOnBattery))
                Toggle(l10n.t(.launchAtLogin), isOn: launchBinding)
                Text(launchCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if settings.loginState == .needsApproval || settings.loginState == .failed {
                    Button(l10n.t(.openLoginSettings)) {
                        LaunchAtLogin.openSettings()
                    }
                }
                Toggle(l10n.t(.showDock), isOn: dockBinding)
                Text(l10n.t(.showDockHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(l10n.t(.menuBarIcon), isOn: binding(\.showMenuBarIcon))
                Text(l10n.t(.menuBarHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(MenuBarMetric.allCases) { metric in
                    Toggle(l10n.metricTitle(metric), isOn: metricBinding(metric))
                }
            } header: {
                Text(l10n.t(.menuBar))
            }

            Section(l10n.t(.widgets)) {
                if settings.settings.widgets.isEmpty {
                    Text(l10n.t(.emptyBoardHint))
                        .foregroundStyle(.secondary)
                }
                ForEach(settings.settings.widgets) { kind in
                    HStack {
                        Text(l10n.widgetTitle(kind))
                        Spacer()
                        Button {
                            settings.move(kind, by: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.borderless)
                        Button {
                            settings.move(kind, by: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.borderless)
                        Button(l10n.t(.hideWidget)) {
                            settings.remove(kind)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                ForEach(WidgetKind.allCases.filter { !settings.settings.widgets.contains($0) }) { kind in
                    HStack {
                        Text(l10n.widgetTitle(kind))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(l10n.t(.add)) { settings.add(kind) }
                            .buttonStyle(.borderless)
                    }
                }
            }

            Section(l10n.t(.notifications)) {
                Toggle(l10n.t(.notifyBattery), isOn: notifyBinding(\.notifyLowBattery))
                HStack {
                    Text(l10n.t(.batteryThreshold))
                    Slider(
                        value: thresholdBinding,
                        in: 0.1...0.4,
                        step: 0.05
                    )
                    Text(Format.percent(settings.settings.lowBatteryThreshold))
                        .frame(width: 44, alignment: .trailing)
                        .monospacedDigit()
                }
                Toggle(l10n.t(.notifyThermal), isOn: notifyBinding(\.notifyThermal))
                Toggle(l10n.t(.notifyMemory), isOn: notifyBinding(\.notifyMemory))
                if !settings.notificationsAllowed {
                    Button(l10n.t(.openNotificationSettings)) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }

            Section(l10n.t(.language)) {
                Picker(l10n.t(.language), selection: languageBinding) {
                    Text(l10n.t(.languageSystem)).tag(AppLanguage.system)
                    Text(l10n.t(.languageArabic)).tag(AppLanguage.arabic)
                    Text(l10n.t(.languageEnglish)).tag(AppLanguage.english)
                }
                Picker(l10n.t(.units), selection: unitBinding) {
                    Text(l10n.t(.bytesUnit)).tag(NetworkUnit.bytes)
                    Text(l10n.t(.bitsUnit)).tag(NetworkUnit.bits)
                }
            }

            Section(l10n.t(.about)) {
                Text(l10n.t(.aboutBody))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                LabeledContent(l10n.t(.version)) {
                    Text(version)
                        .monospacedDigit()
                }
                Button(l10n.t(.quitApp)) {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 560)
        .onAppear {
            settings.loginState = LaunchAtLogin.current()
            monitor.refreshNotificationAuthorization { allowed in
                settings.notificationsAllowed = allowed
            }
        }
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return short
    }

    private var launchCaption: String {
        switch settings.loginState {
        case .on: return l10n.t(.launchOn)
        case .needsApproval: return l10n.t(.launchNeedsApproval)
        case .failed: return l10n.t(.launchFailed)
        case .off, .unknown: return l10n.t(.launchOff)
        }
    }

    private var monitoringBinding: Binding<Bool> {
        Binding(
            get: { settings.settings.monitoringEnabled },
            set: { monitor.setMonitoring($0) }
        )
    }

    private var paceBinding: Binding<RefreshPace> {
        Binding(
            get: { settings.settings.refresh },
            set: { value in settings.update { $0.refresh = value } }
        )
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { settings.settings.launchAtLogin },
            set: { enabled in
                settings.update { $0.launchAtLogin = enabled }
                settings.loginState = LaunchAtLogin.apply(enabled)
            }
        )
    }

    private var dockBinding: Binding<Bool> {
        Binding(
            get: { settings.settings.showDock },
            set: { show in
                settings.update { $0.showDock = show }
                AppRuntime.shared.refreshActivation()
            }
        )
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { settings.settings.language },
            set: { value in settings.update { $0.language = value } }
        )
    }

    private var unitBinding: Binding<NetworkUnit> {
        Binding(
            get: { settings.settings.networkUnit },
            set: { value in settings.update { $0.networkUnit = value } }
        )
    }

    private var thresholdBinding: Binding<Double> {
        Binding(
            get: { settings.settings.lowBatteryThreshold },
            set: { value in settings.update { $0.lowBatteryThreshold = value } }
        )
    }

    private func binding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in settings.update { $0[keyPath: keyPath] = value } }
        )
    }

    private func notifyBinding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in
                settings.update { $0[keyPath: keyPath] = value }
                if value {
                    monitor.requestNotifications()
                }
            }
        )
    }

    private func metricBinding(_ metric: MenuBarMetric) -> Binding<Bool> {
        Binding(
            get: { settings.settings.menuBarMetrics.contains(metric) },
            set: { _ in settings.toggleMetric(metric) }
        )
    }
}
