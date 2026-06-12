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
        item.image = MenuIconFactory.makeIcon()
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
