import SwiftUI
import WidgetKit

struct StatusEntry: TimelineEntry {
    var date: Date
    var payload: WidgetPayload
}

struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: Date(), payload: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        let payload = WidgetSnapshotStore.read().flatMap { saved in
            Date().timeIntervalSince(saved.capturedAt) < 180 ? saved : nil
        } ?? .preview
        completion(StatusEntry(date: Date(), payload: payload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let payload = currentPayload()
        let now = Date()
        let entries = (0..<8).map { index in
            StatusEntry(date: now.addingTimeInterval(Double(index) * 15), payload: payload)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentPayload() -> WidgetPayload {
        if let saved = WidgetSnapshotStore.read(),
           Date().timeIntervalSince(saved.capturedAt) < 180 {
            return saved
        }
        let sampler = Sampler()
        _ = sampler.sample(options: .widget)
        Thread.sleep(forTimeInterval: 0.35)
        return WidgetPayload(snapshot: sampler.sample(options: .widget), arabic: L10n.resolve(.system).isArabic)
    }
}

private struct StatusWidgetEntryView: View {
    var entry: StatusEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        StatusWidgetFace(payload: entry.payload, family: family)
            .environment(\.layoutDirection, entry.payload.arabic ? .rightToLeft : .leftToRight)
            .containerBackground(for: .widget) {
                WidgetBackdrop(mood: entry.payload.machineMood)
            }
    }
}

struct StatusBoardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.muhsan.status.board", provider: StatusProvider()) { entry in
            StatusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Status")
        .description(L10n.resolve(.system).t(.aboutBody))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

@main
struct StatusWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatusBoardWidget()
    }
}
