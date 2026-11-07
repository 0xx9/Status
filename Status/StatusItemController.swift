import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate, NSPopoverDelegate {
    private let settings: SettingsStore
    private let monitor: Monitor
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore, monitor: Monitor) {
        self.settings = settings
        self.monitor = monitor
        super.init()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: panel)
    }

    func install() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        render()
        monitor.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.renderSoon()
            }
            .store(in: &cancellables)
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.renderSoon()
            }
            .store(in: &cancellables)
    }

    private var panel: some View {
        StatusRoot(settings: settings) {
            StatusPanel()
        }
        .environmentObject(monitor)
        .environmentObject(settings)
    }

    private func renderSoon() {
        DispatchQueue.main.async { [weak self] in
            self?.render()
        }
    }

    private func render() {
        guard let button = statusItem.button else { return }
        let l10n = settings.l10n
        let model = MenuBarComposer.model(
            snapshot: monitor.snapshot,
            settings: settings.settings,
            paused: !settings.settings.monitoringEnabled,
            arabic: l10n.isArabic,
            insight: l10n.insightText(monitor.snapshot?.insight ?? .calculating)
        )
        button.toolTip = model.toolTip
        button.setAccessibilityLabel(model.accessibility)
        let fontSize: CGFloat = settings.settings.menuBarMetrics.count >= 3 ? 11 : 13
        button.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        if model.showsSparkline, let image = sparklineImage(model.sparkline) {
            button.image = image
        } else if settings.settings.showMenuBarIcon {
            let image = NSImage(systemSymbolName: model.symbolName, accessibilityDescription: model.toolTip)
            image?.isTemplate = true
            button.image = image
        } else {
            button.image = nil
        }
        button.title = model.title.isEmpty ? "" : (button.image == nil ? model.title : " \(model.title)")
        button.appearsDisabled = !settings.settings.monitoringEnabled
    }

    @objc private func handleClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }
        let right = event.type == .rightMouseUp || event.modifierFlags.contains(.control)
        if right {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            button.highlight(false)
            return
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        button.highlight(true)
    }

    private func showMenu() {
        let menu = buildMenu()
        menu.delegate = self
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    private func buildMenu() -> NSMenu {
        let l10n = settings.l10n
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(item(l10n.t(.details), #selector(openDashboard)))
        menu.addItem(item(l10n.t(.settings), #selector(openSettings)))
        menu.addItem(.separator())
        let monitoring = settings.settings.monitoringEnabled
        menu.addItem(item(monitoring ? l10n.t(.pause) : l10n.t(.resume), #selector(toggleMonitoring)))
        menu.addItem(item(l10n.t(.refresh), #selector(refresh)))
        menu.addItem(.separator())
        let quit = item(l10n.t(.quitApp), #selector(quit))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
    }

    @objc private func openDashboard() {
        popover.performClose(nil)
        AppRuntime.shared.openDashboard()
    }

    @objc private func openSettings() {
        popover.performClose(nil)
        AppRuntime.shared.openSettings()
    }

    @objc private func toggleMonitoring() {
        monitor.setMonitoring(!settings.settings.monitoringEnabled)
    }

    @objc private func refresh() {
        monitor.refreshNow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func sparklineImage(_ values: [Double]) -> NSImage? {
        guard values.count >= 2 else { return nil }
        let width: CGFloat = 54
        let height: CGFloat = 14
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
            let path = NSBezierPath()
            path.lineWidth = 1.25
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            let peak = max(values.max() ?? 1, 0.05)
            for (index, value) in values.enumerated() {
                let x = width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                let y = 1 + (height - 2) * CGFloat(min(max(value, 0), peak) / peak)
                let point = CGPoint(x: x, y: y)
                if index == 0 { path.move(to: point) } else { path.line(to: point) }
            }
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
