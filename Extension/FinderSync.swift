import Cocoa
import FinderSync
import UnquarantineCore

class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Observe the whole filesystem so the menu is available everywhere.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        guard menuKind == .contextualMenuForItems else { return menu }
        let item = NSMenuItem(title: "Remove Quarantine & Re-sign",
                              action: #selector(strip(_:)),
                              keyEquivalent: "")
        item.target = self
        // Reuse a system SF Symbol so the item matches native Finder menu icons and
        // adapts to light/dark automatically (a template image renders in the menu's
        // label color). The filled variant + regular weight reads better than the thin
        // outline at menu size.
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if let base = NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: "Remove quarantine") {
            let icon = base.withSymbolConfiguration(iconConfig) ?? base
            icon.isTemplate = true
            item.image = icon
        }
        menu.addItem(item)
        return menu
    }

    @objc func strip(_ sender: AnyObject?) {
        guard let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty else { return }
        let encoded = PathCodec.encode(urls.map { $0.path })
        guard let url = URL(string: "unquarantine://strip?paths=\(encoded)") else { return }
        NSWorkspace.shared.open(url)
    }
}
