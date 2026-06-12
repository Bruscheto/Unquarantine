import AppKit

enum MenuIconAppearance {
    static func tintColor(for appearance: NSAppearance?) -> NSColor {
        let match = appearance?.bestMatch(from: [
            .darkAqua,
            .accessibilityHighContrastDarkAqua,
            .vibrantDark,
            .aqua,
            .accessibilityHighContrastAqua,
            .vibrantLight
        ])
        return switch match {
        case .darkAqua, .accessibilityHighContrastDarkAqua, .vibrantDark:
            .white
        default:
            .black
        }
    }
}

enum MenuIconFactory {
    static func makeIcon(appearance: NSAppearance? = nil) -> NSImage? {
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = NSImage(named: NSImage.Name("MenuIcon"))
            ?? NSImage(systemSymbolName: "lock.slash", accessibilityDescription: "Remove quarantine")?
            .withSymbolConfiguration(symbolConfig)
        return image?.tinted(with: MenuIconAppearance.tintColor(for: appearance ?? NSAppearance.currentDrawing()))
    }
}

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        draw(in: NSRect(origin: .zero, size: size),
             from: NSRect(origin: .zero, size: size),
             operation: .sourceOver,
             fraction: 1)
        color.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
