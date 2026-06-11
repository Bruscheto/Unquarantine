# Unquarantine

A tiny macOS app that adds **Remove Quarantine & Re-sign** to Finder's right-click
menu — strips `com.apple.quarantine` and ad-hoc re-signs the file, fixing the
"unidentified developer" / "app is damaged" Gatekeeper blocks. One password prompt,
a notification, done. (A weekend project.)

## Install

Download [Unquarantine.dmg](https://github.com/Bruscheto/Unquarantine/releases/latest),
drag it into Applications.

It's ad-hoc signed, so macOS blocks the first launch (ironic, I know). Open it once
with **right-click → Open**, then in the setup window click **Open Extension Settings**
and enable **UnquarantineFinderExtension**.

> If the right-click item doesn't show up, log out and back in once — macOS caches
> Finder extensions.

## Use

Right-click any file in Finder → **Remove Quarantine & Re-sign** → enter your password.
It runs in the background and pings you with a notification. That's it.

## Build

Needs Xcode + `brew install xcodegen`.

```sh
xcodegen generate && open Unquarantine.xcodeproj   # run the "Unquarantine" scheme
bash tools/make_dmg.sh                              # or package a dmg → dist/
```
