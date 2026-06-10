# Unquarantine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A macOS app + Finder Sync extension that adds a right-click "Remove Quarantine & Re-sign" menu item which strips `com.apple.quarantine` and ad-hoc re-signs the selected files via a single admin password prompt.

**Architecture:** Pure logic (path encoding, shell-command building, AppleScript result mapping) lives in a `swift test`-able SwiftPM package `UnquarantineCore`. A non-sandboxed host app (`Unquarantine.app`) and a sandboxed `UnquarantineFinderExtension` (built with XcodeGen) both depend on that package. The extension builds a `unquarantine://strip?paths=…` URL; the host app decodes it and runs the privileged shell via `NSAppleScript` `do shell script … with administrator privileges`.

**Tech Stack:** Swift 5.10, SwiftPM, XcodeGen, FinderSync, NSAppleScript, UserNotifications, XCTest.

---

## File Structure

```
Unquarantine/
├─ Core/                              # SwiftPM package (swift test, no Xcode needed)
│  ├─ Package.swift
│  ├─ Sources/UnquarantineCore/
│  │  ├─ PathCodec.swift              # encode/decode paths <-> URL query value
│  │  ├─ CommandBuilder.swift         # build the single-line privileged shell script
│  │  └─ AppleScriptResult.swift      # map NSAppleScript error -> result enum
│  └─ Tests/UnquarantineCoreTests/
│     ├─ PathCodecTests.swift
│     ├─ CommandBuilderTests.swift
│     └─ AppleScriptResultTests.swift
├─ project.yml                        # XcodeGen spec for the two app targets
├─ App/                               # Unquarantine.app (host, sandbox OFF)
│  ├─ UnquarantineApp.swift           # @main SwiftUI App + onOpenURL handling
│  ├─ ContentView.swift               # minimal status window
│  ├─ AppStatus.swift                 # ObservableObject holding last-run status
│  ├─ PrivilegedRunner.swift          # NSAppleScript admin execution
│  ├─ Notifier.swift                  # UNUserNotificationCenter result notification
│  ├─ Info.plist                      # CFBundleURLTypes: unquarantine scheme
│  └─ Unquarantine.entitlements       # sandbox OFF
└─ Extension/                         # UnquarantineFinderExtension (.appex, sandboxed)
   ├─ FinderSync.swift                # FIFinderSync subclass + menu
   ├─ Info.plist                      # NSExtension FinderSync config
   └─ Extension.entitlements          # sandbox ON
```

---

## Task 0: Prerequisites (manual, one-time)

**Files:** none.

These are environment requirements. The agent should verify them and STOP with instructions if missing — they cannot be auto-installed unattended (Xcode is a large download).

- [ ] **Step 1: Verify / install XcodeGen**

Run: `which xcodegen || brew install xcodegen`
Expected: a path like `/opt/homebrew/bin/xcodegen`.

- [ ] **Step 2: Verify full Xcode is present and selected (needed only for Tasks 5–6)**

Run: `xcodebuild -version`
Expected: `Xcode 15.x` (or later). If it instead prints
`tool 'xcodebuild' requires Xcode … Command Line Tools`, then full Xcode is not
active. Resolve by installing Xcode from the App Store, then:
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

Note: Tasks 1–4 (the `UnquarantineCore` package) only need the Swift toolchain that
ships with Command Line Tools and can proceed even if full Xcode is not yet
installed.

---

## Task 1: Scaffold the UnquarantineCore SwiftPM package

**Files:**
- Create: `Core/Package.swift`
- Create: `Core/Sources/UnquarantineCore/PathCodec.swift` (stub so the target compiles)
- Create: `Core/Tests/UnquarantineCoreTests/SmokeTests.swift`

- [ ] **Step 1: Write `Core/Package.swift`**

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "UnquarantineCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "UnquarantineCore", targets: ["UnquarantineCore"])
    ],
    targets: [
        .target(name: "UnquarantineCore"),
        .testTarget(
            name: "UnquarantineCoreTests",
            dependencies: ["UnquarantineCore"]
        )
    ]
)
```

- [ ] **Step 2: Write a minimal stub so the target compiles**

`Core/Sources/UnquarantineCore/PathCodec.swift`:

```swift
public enum PathCodec {}
```

- [ ] **Step 3: Write a smoke test**

`Core/Tests/UnquarantineCoreTests/SmokeTests.swift`:

```swift
import XCTest
@testable import UnquarantineCore

final class SmokeTests: XCTestCase {
    func testPackageCompiles() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: Run the tests**

Run: `cd Core && swift test`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
cd /Users/brus/Codes/Projects/Unquarantine
git add Core
git commit -m "chore: scaffold UnquarantineCore swiftpm package"
```

---

## Task 2: PathCodec (encode/decode selected paths <-> URL query value)

**Files:**
- Modify: `Core/Sources/UnquarantineCore/PathCodec.swift`
- Create: `Core/Tests/UnquarantineCoreTests/PathCodecTests.swift`

**Contract:** `encode([String]) -> String` produces a query value with no characters
that need further URL escaping and no literal commas (commas are the separator, so
any comma inside a path is percent-encoded). `decode(String) -> [String]` is the
exact inverse.

- [ ] **Step 1: Write the failing tests**

`Core/Tests/UnquarantineCoreTests/PathCodecTests.swift`:

```swift
import XCTest
@testable import UnquarantineCore

final class PathCodecTests: XCTestCase {
    func testRoundTripSimple() {
        let paths = ["/Applications/Foo.app"]
        XCTAssertEqual(PathCodec.decode(PathCodec.encode(paths)), paths)
    }

    func testRoundTripMultiple() {
        let paths = ["/Applications/Foo.app", "/Users/x/Bar.app"]
        XCTAssertEqual(PathCodec.decode(PathCodec.encode(paths)), paths)
    }

    func testRoundTripSpecialCharacters() {
        let paths = ["/Users/x/My App, v2.app", "/Users/x/a&b?c .app", "/Users/x/café.app"]
        XCTAssertEqual(PathCodec.decode(PathCodec.encode(paths)), paths)
    }

    func testEncodedValueHasNoLiteralComma() {
        let encoded = PathCodec.encode(["/a,b", "/c"])
        // Exactly one separator comma -> exactly one split point.
        XCTAssertEqual(encoded.split(separator: ",").count, 2)
    }

    func testDecodeEmptyReturnsEmpty() {
        XCTAssertEqual(PathCodec.decode(""), [])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd Core && swift test --filter PathCodecTests`
Expected: FAIL (no `encode`/`decode` members).

- [ ] **Step 3: Implement PathCodec**

`Core/Sources/UnquarantineCore/PathCodec.swift`:

```swift
import Foundation

public enum PathCodec {
    /// Characters left un-escaped. Deliberately excludes "," so the comma can be
    /// used as an unambiguous separator between encoded paths.
    private static let allowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    public static func encode(_ paths: [String]) -> String {
        paths
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? $0 }
            .joined(separator: ",")
    }

    public static func decode(_ value: String) -> [String] {
        value
            .split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.removingPercentEncoding ?? String($0) }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd Core && swift test --filter PathCodecTests`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/brus/Codes/Projects/Unquarantine
git add Core
git commit -m "feat(core): add PathCodec for url-safe path encoding"
```

---

## Task 3: CommandBuilder (build the privileged shell script)

**Files:**
- Create: `Core/Sources/UnquarantineCore/CommandBuilder.swift`
- Create: `Core/Tests/UnquarantineCoreTests/CommandBuilderTests.swift`

**Contract:** `build(paths:)` returns a single-line `/bin/sh` script. For each path it
strips quarantine best-effort (`|| true`, so an absent attribute never fails the run)
and ad-hoc re-signs (`|| status=1`, so a real signing failure is reported). It exits
non-zero if any re-sign failed. `shellQuote` single-quotes a path safely so filenames
cannot inject shell syntax. Single-line (semicolon-joined) because the script is later
embedded inside an AppleScript string literal.

- [ ] **Step 1: Write the failing tests**

`Core/Tests/UnquarantineCoreTests/CommandBuilderTests.swift`:

```swift
import XCTest
@testable import UnquarantineCore

final class CommandBuilderTests: XCTestCase {
    func testShellQuoteWrapsInSingleQuotes() {
        XCTAssertEqual(CommandBuilder.shellQuote("/a/b"), "'/a/b'")
    }

    func testShellQuoteEscapesEmbeddedSingleQuote() {
        XCTAssertEqual(CommandBuilder.shellQuote("a'b"), "'a'\\''b'")
    }

    func testBuildIsSingleLine() {
        let script = CommandBuilder.build(paths: ["/a", "/b"])
        XCTAssertFalse(script.contains("\n"))
    }

    func testBuildContainsBothCommandsPerPath() {
        let script = CommandBuilder.build(paths: ["/Applications/Foo.app"])
        XCTAssertTrue(script.contains("xattr -r -d com.apple.quarantine '/Applications/Foo.app' 2>/dev/null || true"))
        XCTAssertTrue(script.contains("codesign --force --deep --sign - '/Applications/Foo.app' || status=1"))
    }

    func testBuildInitializesAndExitsWithStatus() {
        let script = CommandBuilder.build(paths: ["/a"])
        XCTAssertTrue(script.hasPrefix("status=0;"))
        XCTAssertTrue(script.hasSuffix("exit $status"))
    }

    func testMaliciousFilenameCannotInject() {
        // A filename containing "; rm -rf /" must stay inside the single-quoted token.
        let script = CommandBuilder.build(paths: ["/x/; rm -rf /"])
        XCTAssertTrue(script.contains("'/x/; rm -rf /'"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd Core && swift test --filter CommandBuilderTests`
Expected: FAIL (no `CommandBuilder`).

- [ ] **Step 3: Implement CommandBuilder**

`Core/Sources/UnquarantineCore/CommandBuilder.swift`:

```swift
public enum CommandBuilder {
    /// Single-quote a path for safe POSIX shell embedding.
    public static func shellQuote(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Build a single-line /bin/sh script that strips quarantine (best-effort) and
    /// ad-hoc re-signs each path, exiting non-zero if any re-sign fails.
    public static func build(paths: [String]) -> String {
        var parts = ["status=0"]
        for path in paths {
            let quoted = shellQuote(path)
            parts.append("xattr -r -d com.apple.quarantine \(quoted) 2>/dev/null || true")
            parts.append("codesign --force --deep --sign - \(quoted) || status=1")
        }
        parts.append("exit $status")
        return parts.joined(separator: "; ")
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd Core && swift test --filter CommandBuilderTests`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/brus/Codes/Projects/Unquarantine
git add Core
git commit -m "feat(core): add CommandBuilder for the privileged shell script"
```

---

## Task 4: AppleScriptResult (map NSAppleScript errors)

**Files:**
- Create: `Core/Sources/UnquarantineCore/AppleScriptResult.swift`
- Create: `Core/Tests/UnquarantineCoreTests/AppleScriptResultTests.swift`

**Contract:** `from(errorNumber:message:)` maps a `nil` error number to `.success`,
`-128` (user cancelled the password dialog) to `.cancelled`, and anything else to
`.failed(reason:)` using the message (or a synthesized one).

- [ ] **Step 1: Write the failing tests**

`Core/Tests/UnquarantineCoreTests/AppleScriptResultTests.swift`:

```swift
import XCTest
@testable import UnquarantineCore

final class AppleScriptResultTests: XCTestCase {
    func testNilErrorIsSuccess() {
        XCTAssertEqual(AppleScriptResult.from(errorNumber: nil, message: nil), .success)
    }

    func testMinus128IsCancelled() {
        XCTAssertEqual(AppleScriptResult.from(errorNumber: -128, message: "User cancelled."), .cancelled)
    }

    func testOtherErrorIsFailedWithMessage() {
        XCTAssertEqual(
            AppleScriptResult.from(errorNumber: 1, message: "codesign failed"),
            .failed(reason: "codesign failed")
        )
    }

    func testOtherErrorWithoutMessageSynthesizesReason() {
        XCTAssertEqual(
            AppleScriptResult.from(errorNumber: 42, message: nil),
            .failed(reason: "Unknown error (42)")
        )
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd Core && swift test --filter AppleScriptResultTests`
Expected: FAIL (no `AppleScriptResult`).

- [ ] **Step 3: Implement AppleScriptResult**

`Core/Sources/UnquarantineCore/AppleScriptResult.swift`:

```swift
public enum AppleScriptResult: Equatable {
    case success
    case cancelled
    case failed(reason: String)

    public static func from(errorNumber: Int?, message: String?) -> AppleScriptResult {
        guard let errorNumber else { return .success }
        if errorNumber == -128 { return .cancelled }
        return .failed(reason: message ?? "Unknown error (\(errorNumber))")
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd Core && swift test --filter AppleScriptResultTests`
Expected: PASS (4 tests).

- [ ] **Step 5: Run the whole suite and commit**

Run: `cd Core && swift test`
Expected: PASS (all tests across the four test files).

```bash
cd /Users/brus/Codes/Projects/Unquarantine
git add Core
git commit -m "feat(core): add AppleScriptResult error mapping"
```

---

## Task 5: App + Extension via XcodeGen

> Requires full Xcode (Task 0, Step 2). All source below is complete — no placeholders.

**Files:**
- Create: `project.yml`
- Create: `App/UnquarantineApp.swift`, `App/ContentView.swift`, `App/AppStatus.swift`,
  `App/PrivilegedRunner.swift`, `App/Notifier.swift`, `App/Info.plist`,
  `App/Unquarantine.entitlements`
- Create: `Extension/FinderSync.swift`, `Extension/Info.plist`,
  `Extension/Extension.entitlements`

- [ ] **Step 1: Write `project.yml`**

```yaml
name: Unquarantine
options:
  bundleIdPrefix: com.brus.unquarantine
  deploymentTarget:
    macOS: "13.0"
packages:
  UnquarantineCore:
    path: Core
targets:
  Unquarantine:
    type: application
    platform: macOS
    sources: [App]
    info:
      path: App/Info.plist
      properties:
        CFBundleURLTypes:
          - CFBundleURLName: com.brus.unquarantine.url
            CFBundleURLSchemes: [unquarantine]
        LSUIElement: false
    settings:
      base:
        CODE_SIGN_ENTITLEMENTS: App/Unquarantine.entitlements
        ENABLE_HARDENED_RUNTIME: NO
        GENERATE_INFOPLIST_FILE: NO
    dependencies:
      - package: UnquarantineCore
      - target: UnquarantineFinderExtension
        embed: true
  UnquarantineFinderExtension:
    type: app-extension
    platform: macOS
    sources: [Extension]
    info:
      path: Extension/Info.plist
    settings:
      base:
        CODE_SIGN_ENTITLEMENTS: Extension/Extension.entitlements
        GENERATE_INFOPLIST_FILE: NO
    dependencies:
      - package: UnquarantineCore
```

- [ ] **Step 2: Write the host app entitlements (sandbox OFF)**

`App/Unquarantine.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

- [ ] **Step 3: Write the host app Info.plist**

`App/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
```

- [ ] **Step 4: Write `App/AppStatus.swift`**

```swift
import Foundation
import UnquarantineCore

@MainActor
final class AppStatus: ObservableObject {
    @Published var lastMessage: String = "Right-click a file in Finder and choose “Remove Quarantine & Re-sign”."

    func update(_ result: AppleScriptResult, count: Int) {
        switch result {
        case .success:
            lastMessage = "Done — processed \(count) item\(count == 1 ? "" : "s")."
        case .cancelled:
            lastMessage = "Cancelled."
        case .failed(let reason):
            lastMessage = "Failed: \(reason)"
        }
    }
}
```

- [ ] **Step 5: Write `App/PrivilegedRunner.swift`**

```swift
import Foundation
import UnquarantineCore

enum PrivilegedRunner {
    /// Run `script` (a single-line /bin/sh script) as administrator. Shows the
    /// standard macOS password dialog once.
    static func run(script: String) -> AppleScriptResult {
        let source = "do shell script \"\(escapeForAppleScript(script))\" with administrator privileges"
        guard let appleScript = NSAppleScript(source: source) else {
            return .failed(reason: "Could not construct AppleScript.")
        }
        var errorInfo: NSDictionary?
        appleScript.executeAndReturnError(&errorInfo)
        let number = errorInfo?["NSAppleScriptErrorNumber"] as? Int
        let message = errorInfo?["NSAppleScriptErrorMessage"] as? String
        return AppleScriptResult.from(errorNumber: number, message: message)
    }

    /// Escape a string for embedding inside an AppleScript double-quoted literal.
    private static func escapeForAppleScript(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
```

- [ ] **Step 6: Write `App/Notifier.swift`**

```swift
import Foundation
import UserNotifications
import UnquarantineCore

enum Notifier {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func notify(_ result: AppleScriptResult, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Unquarantine"
        switch result {
        case .success:
            content.body = "Done — processed \(count) item\(count == 1 ? "" : "s")."
        case .cancelled:
            content.body = "Cancelled."
        case .failed(let reason):
            content.body = "Failed: \(reason)"
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] **Step 7: Write `App/ContentView.swift`**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var status: AppStatus

    var body: some View {
        VStack(spacing: 16) {
            Text("Unquarantine")
                .font(.title2).bold()
            Text(status.lastMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Enable the Finder extension in System Settings → General → Login Items & Extensions.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 380, height: 200)
    }
}
```

- [ ] **Step 8: Write `App/UnquarantineApp.swift`**

```swift
import SwiftUI
import UnquarantineCore

@main
struct UnquarantineApp: App {
    @StateObject private var status = AppStatus()

    init() {
        Notifier.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(status)
                .onOpenURL { handle($0) }
        }
        .windowResizability(.contentSize)
    }

    private func handle(_ url: URL) {
        guard url.scheme == "unquarantine", url.host == "strip",
              let query = url.query, query.hasPrefix("paths=") else { return }
        let value = String(query.dropFirst("paths=".count))
        let paths = PathCodec.decode(value).filter { FileManager.default.fileExists(atPath: $0) }
        guard !paths.isEmpty else { return }

        let script = CommandBuilder.build(paths: paths)
        let result = PrivilegedRunner.run(script: script)
        Notifier.notify(result, count: paths.count)
        status.update(result, count: paths.count)
    }
}
```

- [ ] **Step 9: Write the extension entitlements (sandbox ON)**

`Extension/Extension.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 10: Write the extension Info.plist**

`Extension/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.FinderSync</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).FinderSync</string>
    </dict>
</dict>
</plist>
```

- [ ] **Step 11: Write `Extension/FinderSync.swift`**

```swift
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
```

- [ ] **Step 12: Generate the Xcode project and build**

Run:
```bash
cd /Users/brus/Codes/Projects/Unquarantine
xcodegen generate
xcodebuild -project Unquarantine.xcodeproj -scheme Unquarantine -configuration Debug build
```
Expected: `** BUILD SUCCEEDED **`. If signing errors appear, open the project once in
Xcode and set the team to your personal team for both targets (automatic signing),
then re-run the build.

- [ ] **Step 13: Add `.gitignore` and commit**

`.gitignore`:

```
.DS_Store
build/
DerivedData/
*.xcodeproj
```

> The `.xcodeproj` is generated from `project.yml`, so it is intentionally ignored.

```bash
cd /Users/brus/Codes/Projects/Unquarantine
git add project.yml App Extension .gitignore
git commit -m "feat: add Unquarantine host app and Finder extension"
```

---

## Task 6: Manual verification + README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Run the host app to register the extension**

Build & run once from Xcode (Cmd-R), or build then `open` the product. Launching the
app registers the bundled extension with the system.

- [ ] **Step 2: Enable the extension**

Open System Settings → General → Login Items & Extensions → (Finder/File Provider
extensions) and toggle **UnquarantineFinderExtension** on.

- [ ] **Step 3: Manual test checklist (record pass/fail for each)**

1. Download an unsigned app; confirm Gatekeeper blocks first launch.
2. Right-click it → **Remove Quarantine & Re-sign** → enter password once.
3. Confirm the success notification appears.
4. Confirm the app now launches normally.
5. Run `xattr -p com.apple.quarantine <app>`; expect "No such xattr".
6. Repeat the right-click but click **Cancel** at the password dialog → expect a
   "Cancelled" notification and no error.
7. Select two files at once → expect a single password prompt covering both.

- [ ] **Step 4: Write `README.md`**

```markdown
# Unquarantine

Right-click any file in Finder → **Remove Quarantine & Re-sign** to strip
`com.apple.quarantine` and ad-hoc re-sign it, fixing the "unidentified developer"
and "app is damaged" Gatekeeper blocks — with a single admin password prompt.

## Architecture
- `Core/` — `UnquarantineCore` SwiftPM package with the pure, unit-tested logic
  (`PathCodec`, `CommandBuilder`, `AppleScriptResult`). Run `cd Core && swift test`.
- `App/` — `Unquarantine.app` (sandbox off): handles the `unquarantine://` URL,
  runs the privileged shell via `NSAppleScript`, posts a notification.
- `Extension/` — sandboxed Finder Sync extension providing the context-menu item.

## Build
Requires full Xcode and XcodeGen (`brew install xcodegen`).

    xcodegen generate
    xcodebuild -project Unquarantine.xcodeproj -scheme Unquarantine build

Run the app once, then enable the extension in
System Settings → General → Login Items & Extensions.

## Notes
This bypasses Gatekeeper on items you explicitly select. Only use it on software you
trust.
```

- [ ] **Step 5: Commit**

```bash
cd /Users/brus/Codes/Projects/Unquarantine
git add README.md
git commit -m "docs: add README and manual verification checklist"
```

---

## Self-Review Notes

- **Spec coverage:** two-target architecture (Tasks 1,5), AppleScript admin prompt
  (Task 5 PrivilegedRunner), quarantine + ad-hoc re-sign (Task 3), any-file trigger +
  notification (Task 5 FinderSync/Notifier), pure-logic unit tests (Tasks 2–4),
  manual checklist (Task 6) — all covered.
- **Type consistency:** `AppleScriptResult.from(errorNumber:message:)`,
  `PathCodec.encode/decode`, `CommandBuilder.build(paths:)/shellQuote`,
  `AppStatus.update(_:count:)`, `Notifier.notify(_:count:)` are used identically
  wherever they appear.
- **Known nuance:** the FinderSync extension watching `/` makes the menu appear
  everywhere; acceptable per the "any file" decision in the spec.
