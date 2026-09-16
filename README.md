<p align="center">
  <img src="assets/tideline-logo.png" width="420" alt="Tideline">
</p>

Tideline manages, sorts, and cleans up Safari bookmarks on macOS and iOS: duplicate
detection, folder sorting (by domain / date / tag), dead-link checking, and tagging + search.

## How it works

Safari doesn't let apps read its bookmarks directly — especially on iOS, which has no
file-level access to Safari's data. The only supported path on both platforms is a
**Safari Web Extension**, using the `browser.bookmarks` JavaScript API. So Tideline is
three pieces:

- **`Core/`** — a platform-independent Swift package (`TidelineCore`) with the actual
  logic: duplicate detection, folder sorting strategies, dead-link checking, search. No
  UI, no Safari APIs — just types and algorithms, fully unit tested.
- **`Extension/`** — the Safari Web Extension (`manifest.json`, `background.js`, a popup)
  that talks to `browser.bookmarks`, plus `SafariWebExtensionHandler.swift`, the native
  bridge Safari routes `sendNativeMessage` calls to.
- **`App/`** — the SwiftUI app (macOS + iOS, sharing views/state from `App/Shared`) that
  presents the bookmark data and drives sorting/dedup/dead-link actions.

The app and the extension can't call each other directly — Safari only runs the
extension's JS in response to its own triggers (popup opened, a bookmarks change). So
they hand data back and forth through files in an **App Group container**
(`group.au.id.cavanaghs.Tideline`): the extension writes a bookmarks snapshot, the app
reads it and queues up any changes the user makes, and the extension drains that queue
next time it runs (currently: whenever its popup is opened). See the comments in
`App/Shared/Models/SafariBookmarksBridge.swift` and `Extension/Shared/background.js` for
the exact protocol.

## Known limitations / TODOs

- **`applyFolderDiff`'s target parent folder is unverified** (`Extension/Shared/background.js`).
  It creates sorted folders under Safari's real tree root's first child (normally the
  bookmarks bar / Favorites), since the true root usually isn't a valid `bookmarks.create`
  parent — confirm this against a real Safari install. It also doesn't delete the
  (now-empty) folders bookmarks get moved out of; that's left as a manual cleanup, or a
  future explicit, user-confirmed operation, since deleting folders is destructive.
- **Background execution model: sourced, not device-tested.** `manifest.json` declares
  `background.scripts` + `persistent: false` (a non-persistent event page), per Apple's
  [Safari Web Extension browser-compatibility
  docs](https://developer.apple.com/documentation/safariservices/safari_web_extensions/assessing_your_safari_web_extension_s_browser_compatibility)
  — Chrome's `background.service_worker` convention is known to be unreliable on iOS
  Safari specifically. There are still unresolved reports of Safari terminating background
  pages mid-task on iOS, which `syncNow()`'s drain-then-push design is meant to tolerate,
  but none of this has been confirmed against a real Safari build yet.
- **Tags aren't round-tripped through Safari** — `browser.bookmarks` has no native concept
  of tags, so `Bookmark.tags` is currently just in-memory app state, not persisted back to
  Safari. A real implementation likely needs to encode tags into the bookmark title or a
  separate store in the App Group container.

## Building

You need a full Xcode install (not just the Command Line Tools) to build any of this —
the app and extension targets require the iOS/macOS SDKs and code signing that Xcode
provides.

```sh
brew install xcodegen   # already done if you're reading this after setup
xcodegen generate       # turns project.yml into Tideline.xcodeproj
open Tideline.xcodeproj
```

The generated `.xcodeproj` is gitignored — `project.yml` is the source of truth. Re-run
`xcodegen generate` after editing it or after adding/removing source files.

In Xcode, you'll need to:
1. Set your Apple Developer Team on each of the four targets (`Tideline-macOS`,
   `Tideline-iOS`, `TidelineExtension-macOS`, `TidelineExtension-iOS`).
2. Create the `group.au.id.cavanaghs.Tideline` App Group under your account (Signing &
   Capabilities → App Groups) if it doesn't already exist.
3. Enable the Tideline extension in Safari's settings once the app has run once.

### Testing the Core package standalone

`TidelineCore` has no dependency on Xcode-only frameworks and can be tested with the
Swift toolchain alone — once Xcode (not just Command Line Tools) is installed:

```sh
cd Core && swift test
```

## Distribution

- **GitHub** — source lives here.
- **Homebrew Cask** — `Homebrew/tideline.rb` is a template cask pointing at a GitHub
  Release zip of the notarized `Tideline.app`. Fill in the real `sha256` after cutting a
  release, then submit it to `homebrew-cask` (or host it in a personal tap first).
- **TestFlight / App Store** — planned; the macOS target is already sandboxed
  (`App/macOS/Tideline.entitlements`) with hardened runtime enabled, which both
  notarization and Mac App Store submission require.

## License

MIT — see [LICENSE](LICENSE).
