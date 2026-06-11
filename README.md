# Unquarantine

Right-click any file in Finder → **Remove Quarantine & Re-sign** to strip
`com.apple.quarantine` and ad-hoc re-sign it, fixing the "unidentified developer"
and "app is damaged and should be moved to the Trash" Gatekeeper blocks — with a
single admin password prompt.

## Architecture

- `Core/` — the `UnquarantineCore` SwiftPM package with the pure, unit-tested logic
  (`PathCodec`, `CommandBuilder`, `AppleScriptResult`, and the `message(count:)`
  helper). Runs without Xcode: `cd Core && swift test`.
- `App/` — `Unquarantine.app` (App Sandbox **off**): registers the `unquarantine://`
  URL scheme, decodes the selected paths, runs the privileged shell via
  `NSAppleScript` (`do shell script … with administrator privileges`), and posts a
  notification.
- `Extension/` — a sandboxed Finder Sync extension that adds the context-menu item and
  opens `unquarantine://strip?paths=…`.
- `project.yml` — the single source of truth. The `.xcodeproj` and both `Info.plist`
  files are generated from it and are gitignored.

## Build

Requires full Xcode and XcodeGen (`brew install xcodegen`).

```sh
xcodegen generate
xcodebuild -project Unquarantine.xcodeproj -scheme Unquarantine -configuration Debug build
```

The project is ad-hoc signed (`CODE_SIGN_IDENTITY: "-"`), so it builds and runs
locally with no Apple Developer account. To run on another Mac, switch to a real
Developer ID / personal team in `project.yml`.

## Install & enable

1. Build and run the app once (Xcode ⌘R, or `open` the built product). Launching it
   registers the bundled extension with the system.
2. Open **System Settings → General → Login Items & Extensions** and enable
   **UnquarantineFinderExtension**.

## Manual test checklist

1. Download an unsigned app; confirm Gatekeeper blocks first launch.
2. Right-click it → **Remove Quarantine & Re-sign** → enter your password once.
3. Confirm the success notification appears and the app now launches.
4. `xattr -p com.apple.quarantine <app>` should report no such attribute.
5. Repeat and **Cancel** the password dialog → no error, no notification.
6. Select two files at once → a single password prompt covers both.

## Notes

This bypasses Gatekeeper on items you explicitly select. Only use it on software you
trust. Ad-hoc re-signing (`codesign --force --deep --sign -`) is what fixes the
"damaged app" case that quarantine removal alone does not.
