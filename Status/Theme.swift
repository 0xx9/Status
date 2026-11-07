import AppKit
import SwiftUI

enum Palette {
    static let tint = Color(red: 0.16, green: 0.52, blue: 0.45)

    static func mood(_ mood: MachineMood, scheme: ColorScheme) -> Color {
        switch mood {
        case .calm:
            return scheme == .dark
                ? Color(red: 0.49, green: 0.84, blue: 0.72)
                : Color(red: 0.09, green: 0.42, blue: 0.36)
        case .busy:
            return scheme == .dark
                ? Color(red: 0.95, green: 0.74, blue: 0.40)
                : Color(red: 0.70, green: 0.44, blue: 0.08)
        case .strained, .hot:
            return scheme == .dark
                ? Color(red: 0.96, green: 0.58, blue: 0.50)
                : Color(red: 0.73, green: 0.28, blue: 0.22)
        case .lowBattery:
            return scheme == .dark
                ? Color(red: 0.95, green: 0.70, blue: 0.38)
                : Color(red: 0.72, green: 0.42, blue: 0.10)
        }
    }

    static var canvas: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if dark {
                return NSColor(srgbRed: 0.102, green: 0.110, blue: 0.114, alpha: 1)
            }
            return NSColor(srgbRed: 0.965, green: 0.960, blue: 0.945, alpha: 1)
        }))
    }

    static var card: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if dark {
                return NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.055)
            }
            return NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.78)
        }))
    }

    static var stroke: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if dark {
                return NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10)
            }
            return NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.06)
        }))
    }

    static var canvasNSColor: NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if dark {
                return NSColor(srgbRed: 0.102, green: 0.110, blue: 0.114, alpha: 1)
            }
            return NSColor(srgbRed: 0.965, green: 0.960, blue: 0.945, alpha: 1)
        })
    }
}

struct StatusRoot<Content: View>: View {
    @ObservedObject var settings: SettingsStore
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environment(\.layoutDirection, settings.l10n.isArabic ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: settings.l10n.isArabic ? "ar" : "en"))
            .tint(Palette.tint)
    }
}

extension View {
    func figureFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        font(.system(size: size, weight: weight, design: .rounded))
            .monospacedDigit()
    }
}

enum PanelHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
