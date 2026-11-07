import SwiftUI

struct StatusPanel: View {
    @EnvironmentObject private var monitor: Monitor
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.colorScheme) private var scheme
    @State private var library = false
    @State private var copied = false

    private var l10n: L10n { settings.l10n }
    private var widgets: [WidgetKind] { settings.settings.widgets }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            Divider().opacity(0.4)
            ScrollView {
                VStack(spacing: 8) {
                    if !settings.settings.monitoringEnabled {
                        pausedBanner
                    }
                    if widgets.isEmpty {
                        empty
                    } else {
                        ForEach(widgets) { kind in
                            BoardWidget(kind: kind, style: .compact)
                        }
                    }
                    if library || widgets.isEmpty {
                        WidgetLibrary()
                            .padding(.top, 4)
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: 560)
            Divider().opacity(0.4)
            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 380)
        .background(Palette.canvas)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: PanelHeightKey.self, value: proxy.size.height)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("Status")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                if let snapshot = monitor.snapshot {
                    MoodPill(
                        title: l10n.moodTitle(snapshot.mood),
                        color: Palette.mood(snapshot.mood, scheme: scheme)
                    )
                }
            }
            Text(l10n.insightText(monitor.snapshot?.insight ?? .calculating))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(machineLine)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var machineLine: String {
        guard let identity = monitor.snapshot?.identity else { return l10n.t(.preparing) }
        let name = identity.marketingName.isEmpty ? identity.computerName : identity.marketingName
        let memory = Format.bytes(identity.physicalMemory, base: .binary, arabic: l10n.isArabic).joined
        if identity.chip.isEmpty { return "\(name) · \(memory)" }
        return "\(name) · \(identity.chip) · \(memory)"
    }

    private var pausedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "pause.fill")
                .font(.system(size: 10, weight: .bold))
            Text(pausedText)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Button(l10n.t(.resume)) {
                monitor.setMonitoring(true)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .foregroundStyle(Palette.mood(.busy, scheme: scheme))
        .padding(10)
        .background(Palette.mood(.busy, scheme: scheme).opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var pausedText: String {
        guard let date = monitor.lastCapture else { return l10n.t(.paused) }
        let ago = Format.ago(Date().timeIntervalSince(date), arabic: l10n.isArabic)
        return "\(l10n.t(.paused)) · \(ago)"
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(l10n.t(.emptyBoard))
                .font(.system(size: 14, weight: .semibold))
            Text(l10n.t(.emptyBoardHint))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var footer: some View {
        HStack(spacing: 2) {
            SymbolButton(
                systemName: settings.settings.monitoringEnabled ? "pause" : "play.fill",
                help: settings.settings.monitoringEnabled ? l10n.t(.pause) : l10n.t(.resume)
            ) {
                monitor.setMonitoring(!settings.settings.monitoringEnabled)
            }
            SymbolButton(systemName: "arrow.clockwise", help: l10n.t(.refresh)) {
                monitor.refreshNow()
            }
            SymbolButton(systemName: copied ? "checkmark" : "doc.on.doc", help: copied ? l10n.t(.copied) : l10n.t(.copySummary)) {
                copySummary()
            }
            Spacer()
            SymbolButton(systemName: library ? "xmark" : "plus", help: l10n.t(.addWidget)) {
                withAnimation(.smooth(duration: 0.2)) {
                    library.toggle()
                }
            }
            SymbolButton(systemName: "macwindow", help: l10n.t(.details)) {
                AppRuntime.shared.openDashboard()
            }
            SymbolButton(systemName: "gearshape", help: l10n.t(.settings)) {
                AppRuntime.shared.openSettings()
            }
        }
    }

    private func copySummary() {
        guard let snapshot = monitor.snapshot else { return }
        let text = StatusSummary.make(
            snapshot: snapshot,
            arabic: l10n.isArabic,
            unit: settings.settings.networkUnit
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            copied = false
        }
    }
}
