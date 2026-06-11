# Unquarantine

Strip `com.apple.quarantine` and ad-hoc re-sign any file straight from Finder's
right-click menu — fixing the **"app is from an unidentified developer"** and
**"app is damaged and should be moved to the Trash"** Gatekeeper blocks without
touching Terminal.

Right-click → **Remove Quarantine & Re-sign** → one password prompt → a notification.
No app window, no Dock icon, no fuss.

## Download

Get the latest `.dmg` from [**Releases**](https://github.com/Bruscheto/Unquarantine/releases/latest)
— or directly: [Unquarantine.dmg (v1.0)](https://github.com/Bruscheto/Unquarantine/releases/download/v1.0/Unquarantine.dmg).

1. Open the dmg and drag **Unquarantine** into **Applications**.
2. The build is **ad-hoc signed** (not notarized), so the very first launch is itself
   blocked by Gatekeeper — fitting, given what this app does. Open it once via
   **right-click → Open**, or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Unquarantine.app
   ```
3. On first launch a small setup window appears → click **Open Extension Settings**
   and turn on **UnquarantineFinderExtension** under
   System Settings → General → Login Items & Extensions.
4. If the menu item or its icon doesn't show up, log out and back in once — macOS
   caches Finder extensions per login session.

## Usage

Right-click any file or folder in Finder → **Remove Quarantine & Re-sign**. It:

- runs silently in the background (no window, no Dock icon),
- shows a single admin password prompt covering the whole selection,
- reports success / failure with a notification in the top-right.

Works on apps, disk images, scripts, binaries — anything quarantined. Select multiple
items and one prompt handles them all.

## How it works

A Finder Sync extension is always sandboxed and can't run privileged commands, so it
hands off to a tiny background agent:

- **`Extension/`** — the sandboxed Finder Sync extension. Adds the menu item; on click
  it opens `unquarantine://strip?paths=…`.
- **`App/`** — `Unquarantine.app`, a sandbox-off background agent (`LSUIElement`).
  Handles the URL and runs, via `NSAppleScript`,
  `do shell script "xattr -r -d com.apple.quarantine … ; codesign --force --deep --sign - …" with administrator privileges`,
  then posts the notification. A setup window is shown only when the app is launched
  directly.
- **`Core/`** — the `UnquarantineCore` SwiftPM package with the pure, unit-tested logic
  (`PathCodec`, `CommandBuilder`, `AppleScriptResult`). Runs without Xcode:
  `cd Core && swift test`.
- **`project.yml`** — the single source of truth (XcodeGen). The `.xcodeproj` and both
  `Info.plist` files are generated from it and are gitignored.

## Build from source

Requires Xcode and XcodeGen (`brew install xcodegen`):

```sh
xcodegen generate
xcodebuild -project Unquarantine.xcodeproj -scheme Unquarantine -configuration Debug build
cd Core && swift test          # run the unit tests
```

Package a release disk image:

```sh
bash tools/make_dmg.sh         # → dist/Unquarantine.dmg
```

The project is ad-hoc signed (`CODE_SIGN_IDENTITY: "-"`), so it builds with no Apple
Developer account. To ship a notarized build that opens cleanly on other Macs, set a
Developer ID team in `project.yml` and add signing + notarization to `make_dmg.sh`.

## Caveats

- Stripping quarantine and re-signing **bypasses Gatekeeper** on the items you pick.
  Only use it on software you trust.
- Ad-hoc re-signing (`codesign --force --deep --sign -`) is what fixes the "damaged
  app" case that quarantine removal alone doesn't.
