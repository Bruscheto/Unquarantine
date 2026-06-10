# Unquarantine — Design

**Date:** 2026-06-10
**Status:** Approved (design phase)

## Purpose

A macOS "plugin" that adds a right-click (Finder contextual) menu item letting the
user strip the `com.apple.quarantine` attribute and ad-hoc re-sign any selected
file/folder — fixing the "app can't be opened because it is from an unidentified
developer" and "app is damaged and should be moved to the Trash" cases without
opening a terminal.

Scope is a personal, locally-built tool for the user's own Mac. Not intended for
App Store distribution.

## Form Factor

Native Finder Sync extension (Swift), not a no-code Quick Action. Chosen for the
better UX (item appears directly in the right-click menu) and as a learning /
resume project.

## Architecture — Two Targets

A Finder extension is always sandboxed and cannot run `sudo` / admin AppleScript.
So the extension only provides the menu and hands the work to a non-sandboxed host
app.

### `Unquarantine.app` (host)
- App Sandbox **off** (required to run `do shell script ... with administrator privileges`).
- Minimal SwiftUI window: short instructions + last-run status text.
- Registers custom URL scheme `unquarantine://`.
- Receives `unquarantine://strip?paths=<url-encoded>` requests, runs the privileged
  shell commands via `NSAppleScript`, posts a user notification with the result.

### `UnquarantineFinderExtension` (FinderSync target)
- Sandboxed (required for extensions).
- Adds a contextual menu item **"Remove Quarantine & Re-sign"** on *any* selected
  file or folder (`menu(for: .contextualMenuForItems)`).
- On click: collects `selectedItemURLs()`, URL-encodes the paths, opens
  `unquarantine://strip?paths=…` via `NSWorkspace.shared.open` to launch/route to
  the host app.

## Data Flow

```
Right-click selection
  → extension menu item "Remove Quarantine & Re-sign"
  → NSWorkspace opens unquarantine://strip?paths=<encoded>
  → host app decodes + validates paths
  → ONE NSAppleScript block:  do shell script "<batch>" with administrator privileges
        (single password prompt for the whole batch)
  → post success/failure user notification
```

Per selected path the batch runs:
```sh
xattr -r -d com.apple.quarantine <path>   # best-effort; absence is not an error
codesign --force --deep --sign - <path>   # ad-hoc re-sign; fixes "damaged app"
```

The quarantine removal is best-effort (a missing attribute must not fail the run);
the re-sign handles the "damaged app" case that quarantine removal alone doesn't
solve.

## Components & Boundaries

Pure, testable logic is isolated from the I/O / privileged layers:

- **`PathCodec`** — encode selected paths into the URL query and decode them back.
  Pure functions, unit-tested.
- **`CommandBuilder`** — given validated paths, build the single shell-script string
  (proper quoting/escaping of paths). Pure, unit-tested.
- **`AppleScriptResult`** — map raw `NSAppleScript` error dictionaries to a small
  result enum (`success`, `cancelled` (-128), `failed(reason)`). Pure mapping,
  unit-tested.
- **`PrivilegedRunner`** — thin wrapper that executes the built script via
  `NSAppleScript` and returns a result. Manually tested (involves the password
  dialog).
- **`Notifier`** — posts the result via `UNUserNotificationCenter`.
- **URL handling** in the app delegate / scene wires these together.
- **`FinderSync` subclass** in the extension target builds the menu and opens the URL.

## Error Handling

- Password dialog cancelled → AppleScript error **-128** → notification "Cancelled",
  no error noise.
- Command failure → capture stderr from the script result → notification
  "Failed: <reason>".
- Missing / non-existent paths are filtered out before building the command; an
  empty resulting selection is a no-op (no prompt, no notification spam).

## Testing

XCTest unit tests for the pure logic:
- `PathCodec` round-trips paths including spaces, unicode, `&`, `?`.
- `CommandBuilder` quotes paths safely (no shell injection via filename).
- `AppleScriptResult` maps -128 → cancelled and other codes → failed.

Manual test checklist (privileged + Finder UI cannot be unit-tested):
1. Build & run host app from Xcode; enable the extension in
   System Settings → General → Login Items & Extensions.
2. Download an unsigned app, confirm Gatekeeper blocks it.
3. Right-click it → "Remove Quarantine & Re-sign" → enter password once.
4. Confirm success notification and that the app now launches.
5. Verify `xattr -p com.apple.quarantine <app>` returns no attribute.
6. Cancel the password dialog → confirm "Cancelled" notification, no error.
7. Multi-select two files → confirm a single password prompt covers both.

## Known Constraints

- Locally built with personal-team automatic signing is sufficient for the user's
  own Mac. The extension must be enabled once in System Settings.
- `codesign --deep` is mildly discouraged by Apple but is the standard fix for the
  "damaged app" case and is acceptable for this personal tool.
- Stripping quarantine / re-signing bypasses Gatekeeper protections; this is the
  intended, user-initiated behavior and only runs on explicitly selected items.

## Out of Scope (YAGNI)

- Global Gatekeeper toggle (`spctl`).
- A persistent privileged helper (SMAppService) — re-prompting for the password is
  acceptable.
- App Store / notarized distribution.
