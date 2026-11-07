import AppKit
import SwiftUI
import WidgetKit

@MainActor
final class AppRuntime {
    static let shared = AppRuntime()

    let settings = SettingsStore()
    let monitor: Monitor
    let statusItem: StatusItemController
    private var dashboard: NSWindow?
    private var started = false

    private init() {
        monitor = Monitor(settings: settings)
        statusItem = StatusItemController(settings: settings, monitor: monitor)
    }

    func start() {
        guard !started else { return }
        started = true
        if CommandLine.arguments.contains("--arabic") {
            settings.applyPreviewLanguage(.arabic)
        }
        if CommandLine.arguments.contains("--light") {
            NSApp.appearance = NSAppearance(named: .aqua)
        } else if CommandLine.arguments.contains("--dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        NSApp.setActivationPolicy(settings.settings.showDock ? .regular : .accessory)
        statusItem.install()
        monitor.start()
        if settings.settings.launchAtLogin {
            settings.loginState = LaunchAtLogin.apply(true)
        } else {
            settings.loginState = LaunchAtLogin.current()
        }
        if settings.settings.notifyLowBattery || settings.settings.notifyThermal || settings.settings.notifyMemory {
            monitor.requestNotifications()
        }
        observeWindows()
        let preview = CommandLine.arguments.contains("--open-dashboard")
        if CommandLine.arguments.contains("--preview-panel") {
            openPanelPreview()
        }
        if CommandLine.arguments.contains("--preview-widgets") {
            openWidgetPreview()
        }
        if preview {
            openDashboard()
        } else if !UserDefaults.standard.bool(forKey: "status.didWelcome") {
            UserDefaults.standard.set(true, forKey: "status.didWelcome")
            openDashboard()
        }
    }

    func openDashboard() {
        NSApp.setActivationPolicy(.regular)
        let window = ensureDashboard()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func refreshActivation() {
        let visible = NSApp.windows.contains { window in
            window.isVisible && window.level == .normal && window.styleMask.contains(.titled)
        }
        let policy: NSApplication.ActivationPolicy = (settings.settings.showDock || visible) ? .regular : .accessory
        if NSApp.activationPolicy() != policy {
            NSApp.setActivationPolicy(policy)
        }
    }

    private func openWidgetPreview() {
        let root = StatusRoot(settings: settings) {
            WidgetGallery()
        }
        .environmentObject(monitor)
        .environmentObject(settings)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = "Status Widgets"
        window.setContentSize(NSSize(width: 980, height: 860))
        window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = Palette.canvasNSColor
        window.isReleasedWhenClosed = false
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        widgetPreview = window
    }

    private var widgetPreview: NSWindow?

    private func openPanelPreview() {
        let root = StatusRoot(settings: settings) {
            StatusPanel()
        }
        .environmentObject(monitor)
        .environmentObject(settings)
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: controller)
        window.title = "Status"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = Palette.canvasNSColor
        window.setContentSize(NSSize(width: 380, height: 680))
        window.isReleasedWhenClosed = false
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        panelPreview = window
    }

    private var panelPreview: NSWindow?

    private func ensureDashboard() -> NSWindow {
        if let dashboard { return dashboard }
        let root = StatusRoot(settings: settings) {
            DashboardView()
        }
        .environmentObject(monitor)
        .environmentObject(settings)
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: controller)
        window.title = "Status"
        window.setContentSize(NSSize(width: 1120, height: 760))
        window.minSize = NSSize(width: 880, height: 620)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = Palette.canvasNSColor
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("StatusDashboard")
        window.center()
        dashboard = window
        return window
    }

    private func observeWindows() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                AppRuntime.shared.refreshActivation()
            }
        }
    }
}

struct WidgetGallery: View {
    @EnvironmentObject private var monitor: Monitor
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        let payload = monitor.snapshot.map {
            WidgetPayload(snapshot: $0, arabic: settings.l10n.isArabic)
        } ?? .preview
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                widget("Small", payload, .systemSmall, 170, 170)
                widget("Medium", payload, .systemMedium, 360, 170)
                widget("Large", payload, .systemLarge, 360, 380)
                widget("Extra Large", payload, .systemExtraLarge, 720, 360)
            }
            .padding(28)
            .padding(.top, 12)
        }
        .background(Palette.canvas)
        .environment(\.layoutDirection, settings.l10n.isArabic ? .rightToLeft : .leftToRight)
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            let current = monitor.snapshot.map {
                WidgetPayload(snapshot: $0, arabic: settings.l10n.isArabic)
            } ?? payload
            let folder = URL(fileURLWithPath: "/tmp/status-shots", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let mode = schemeName + (settings.l10n.isArabic ? "-ar" : "")
            export(current, .systemSmall, 170, 170, folder.appendingPathComponent("widget-small-\(mode).png"))
            export(current, .systemMedium, 360, 170, folder.appendingPathComponent("widget-medium-\(mode).png"))
            export(current, .systemLarge, 360, 380, folder.appendingPathComponent("widget-large-\(mode).png"))
            export(current, .systemExtraLarge, 720, 360, folder.appendingPathComponent("widget-extra-\(mode).png"))
        }
    }

    private var schemeName: String {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? "dark" : "light"
    }

    private func export(_ payload: WidgetPayload, _ family: WidgetFamily, _ width: CGFloat, _ height: CGFloat, _ url: URL) {
        let dark = schemeName == "dark"
        let view = StatusWidgetFace(payload: payload, family: family)
            .frame(width: width, height: height)
            .background { WidgetBackdrop(mood: payload.machineMood) }
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.layoutDirection, settings.l10n.isArabic ? .rightToLeft : .leftToRight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: width, height: height)
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }

    private func widget(_ title: String, _ payload: WidgetPayload, _ family: WidgetFamily, _ width: CGFloat, _ height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            StatusWidgetFace(payload: payload, family: family)
                .frame(width: width, height: height)
                .background { WidgetBackdrop(mood: payload.machineMood) }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Palette.stroke, lineWidth: 1)
                }
        }
    }
}

@main
struct StatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            StatusRoot(settings: AppRuntime.shared.settings) {
                SettingsView()
            }
            .environmentObject(AppRuntime.shared.monitor)
            .environmentObject(AppRuntime.shared.settings)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu(AppRuntime.shared.settings.l10n.t(.monitorMenu)) {
                Button(AppRuntime.shared.settings.l10n.t(.refresh)) {
                    AppRuntime.shared.monitor.refreshNow()
                }
                .keyboardShortcut("r")
                Button(AppRuntime.shared.settings.settings.monitoringEnabled
                       ? AppRuntime.shared.settings.l10n.t(.pause)
                       : AppRuntime.shared.settings.l10n.t(.resume)) {
                    AppRuntime.shared.monitor.setMonitoring(!AppRuntime.shared.settings.settings.monitoringEnabled)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }
        AppRuntime.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
