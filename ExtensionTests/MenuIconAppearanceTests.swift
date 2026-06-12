import AppKit
import Testing

@Suite struct MenuIconAppearanceTests {
    @Test func darkAquaUsesWhiteIconTint() {
        #expect(MenuIconAppearance.tintColor(for: NSAppearance(named: .darkAqua)) == .white)
    }

    @Test func aquaUsesBlackIconTint() {
        #expect(MenuIconAppearance.tintColor(for: NSAppearance(named: .aqua)) == .black)
    }
}
