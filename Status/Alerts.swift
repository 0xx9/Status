import Foundation
import UserNotifications

@MainActor
final class StatusAlerts {
    private var startedAt = Date()
    private var batteryLatched = false
    private var thermalLatched = false
    private var memoryLatched = false
    private var asked = false

    func consider(snapshot: SystemSnapshot, settings: AppSettings) {
        guard Date().timeIntervalSince(startedAt) > 20 else { return }
        let l10n = L10n.resolve(settings.language)
        if settings.notifyLowBattery, let battery = snapshot.battery, !battery.isPlugged {
            if battery.fraction <= settings.lowBatteryThreshold {
                if !batteryLatched {
                    batteryLatched = true
                    notify(
                        title: l10n.t(.lowBattery),
                        body: "\(Format.percent(battery.fraction)) · \(l10n.insightText(.lowBattery))"
                    )
                }
            } else if battery.fraction > settings.lowBatteryThreshold + 0.05 {
                batteryLatched = false
            }
        } else {
            batteryLatched = false
        }

        if settings.notifyThermal {
            if snapshot.thermal == .serious || snapshot.thermal == .critical {
                if !thermalLatched {
                    thermalLatched = true
                    notify(title: l10n.t(.hot), body: l10n.insightText(.hot))
                }
            } else {
                thermalLatched = false
            }
        }

        if settings.notifyMemory {
            if snapshot.memory.pressure == .high {
                if !memoryLatched {
                    memoryLatched = true
                    notify(title: l10n.t(.memory), body: l10n.insightText(.memoryStrained))
                }
            } else {
                memoryLatched = false
            }
        }
    }

    func requestAccess() {
        guard !asked else { return }
        asked = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func refreshAuthorization(_ update: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let allowed = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async {
                update(allowed || settings.authorizationStatus == .notDetermined)
            }
        }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "status.\(title).\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
