import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published var loginState: LoginState = .unknown
    @Published var notificationsAllowed = true

    private let defaultsKey = "status.settings.v1"

    var l10n: L10n { L10n.resolve(settings.language) }

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = AppSettings.normalized(decoded)
        } else {
            settings = .standard
        }
    }

    func applyPreviewLanguage(_ language: AppLanguage) {
        var copy = settings
        copy.language = language
        settings = AppSettings.normalized(copy)
    }

    func update(_ body: (inout AppSettings) -> Void) {
        var copy = settings
        body(&copy)
        settings = AppSettings.normalized(copy)
        persist()
    }

    func add(_ kind: WidgetKind) {
        update { $0.widgets = BoardEditing.add(kind, to: $0.widgets) }
    }

    func remove(_ kind: WidgetKind) {
        update { $0.widgets = BoardEditing.remove(kind, from: $0.widgets) }
    }

    func move(_ kind: WidgetKind, by offset: Int) {
        update { $0.widgets = BoardEditing.move(kind, by: offset, in: $0.widgets) }
    }

    func toggleMetric(_ metric: MenuBarMetric) {
        update { $0.menuBarMetrics = BoardEditing.toggle(metric, in: $0.menuBarMetrics) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}

enum LoginState: Equatable {
    case unknown
    case off
    case on
    case needsApproval
    case failed
}
