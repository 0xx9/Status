import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var monitor: Monitor
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.colorScheme) private var scheme
    @State private var library = false
    @State private var copied = false

    private var l10n: L10n { settings.l10n }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Palette.canvas
            Circle()
                .fill(Palette.mood(monitor.snapshot?.mood ?? .calm, scheme: scheme).opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -120, y: -180)
                .allowsHitTesting(false)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if !settings.settings.monitoringEnabled {
                        paused
                    }
                    if settings.settings.widgets.isEmpty {
                        empty
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 340, maximum: 560), spacing: 16)],
                            spacing: 16
                        ) {
                            ForEach(settings.settings.widgets) { kind in
                                BoardWidget(kind: kind, style: .expanded)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 36)
                .padding(.bottom, 28)
            }
        }
        .frame(minWidth: 880, minHeight: 620)
        .sheet(isPresented: $library) {
            librarySheet
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(l10n.t(.yourBoard))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(l10n.insightText(monitor.snapshot?.insight ?? .calculating))
                    .font(.system(size: 15))
                    .foregroundStyle(.primary.opacity(0.82))
                    .padding(.top, 6)
                Text(machineLine)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 10) {
                if let snapshot = monitor.snapshot {
                    MoodPill(
                        title: l10n.moodTitle(snapshot.mood),
                        color: Palette.mood(snapshot.mood, scheme: scheme)
                    )
                }
                HStack(spacing: 4) {
                    SymbolButton(systemName: copied ? "checkmark" : "doc.on.doc", help: l10n.t(.copySummary)) {
                        copySummary()
                    }
                    SymbolButton(systemName: "plus", help: l10n.t(.addWidget)) {
                        library = true
                    }
                    SymbolButton(
                        systemName: settings.settings.monitoringEnabled ? "pause" : "play.fill",
                        help: settings.settings.monitoringEnabled ? l10n.t(.pause) : l10n.t(.resume)
                    ) {
                        monitor.setMonitoring(!settings.settings.monitoringEnabled)
                    }
                    SymbolButton(systemName: "arrow.clockwise", help: l10n.t(.refresh)) {
                        monitor.refreshNow()
                    }
                    SymbolButton(systemName: "gearshape", help: l10n.t(.settings)) {
                        AppRuntime.shared.openSettings()
                    }
                }
            }
        }
    }

    private var machineLine: String {
        guard let identity = monitor.snapshot?.identity else { return l10n.t(.preparing) }
        let name = identity.marketingName.isEmpty ? identity.computerName : identity.marketingName
        if identity.chip.isEmpty { return "\(name) · \(identity.osVersion)" }
        return "\(name) · \(identity.chip) · \(identity.osVersion)"
    }

    private var paused: some View {
        HStack {
            Image(systemName: "pause.fill")
            Text(l10n.t(.paused))
            Spacer()
            Button(l10n.t(.resume)) { monitor.setMonitoring(true) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .font(.system(size: 13, weight: .medium))
        .padding(12)
        .background(Palette.mood(.busy, scheme: scheme).opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Text(l10n.t(.emptyBoard))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(l10n.t(.emptyBoardHint))
                .foregroundStyle(.secondary)
            Button(l10n.t(.addWidget)) { library = true }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var librarySheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t(.library))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text(l10n.t(.boardHint))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(l10n.t(.done)) { library = false }
                    .keyboardShortcut(.cancelAction)
            }
            ScrollView {
                WidgetLibrary()
            }
        }
        .padding(22)
        .frame(width: 480, height: 520)
        .background(Palette.canvas)
    }

    private func copySummary() {
        guard let snapshot = monitor.snapshot else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            StatusSummary.make(snapshot: snapshot, arabic: l10n.isArabic, unit: settings.settings.networkUnit),
            forType: .string
        )
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
    }
}
