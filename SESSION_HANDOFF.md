# Session handoff — Nurse Vault → TestFlight alpha

I'm continuing work on the "Nurse Vault" project in the "Nursing app" folder.
This session (2026-09-26/27) is about getting the alpha onto **TestFlight** — the
user now has a **paid Apple Developer account** and has added it to Xcode on this
Mac. Everything up to the App Store Connect upload is done and committed; the
remaining work is mostly App Store Connect web steps + the user's GUI upload.

## What it is

A private reference-document vault for nursing practice — iPhone, iPad, Mac, and
Apple Watch. Documents (files/photos/notes, up to 48 MB) stored locally and
synced across the user's devices via their PRIVATE CloudKit database. No
third-party servers. Main menu sections: Code Blue, Lab Values, Drugs, Other
(user-addable). Fully offline-capable. Start by reading README.md for full context.

## Project layout (current)

- `NurseVault.xcodeproj` — targets: **NurseVault** (multiplatform: iPhone/iPad/Mac,
  one target, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`),
  **NurseVault Watch** (watchOS, read-only viewer + zoom/pan via Digital Crown),
  **NurseVault Watch Widget** (complication appex, embedded in watch app), and
  three UI-test targets (NurseVaultUITests / NurseVaultMacUITests /
  NurseVaultWatchUITests, sources in AppUITests/ and WatchUITests/).
- `Packages/NurseVaultCore/` — shared Swift package (Core Data model, CloudKit
  sync engine, search, file support, viewers).
- `App/` — SwiftUI app (sidebar, doc list, import flows incl. **camera capture +
  Scan & OCR** (CameraImport.swift), detail/preview/edit, sync badge).
- `Watch/`, `WatchWidget/`, `Support/Info.plist` (widget plist; version now uses
  `$(MARKETING_VERSION)`).
- Bundle IDs: `com.josephwoods.nursevault` + `.watchkitapp` + `.watchkitapp.widget`.
  CloudKit container `iCloud.com.josephwoods.nursevault`. Team **2LFBN27WK8**.
- `.gitignore` covers DerivedData/, build/, build-logs/, archives/, *.moved-aside.
- `build/export/export/NurseVault Watch.ipa` — the exported TestFlight .ipa
  (gitignored; regenerate per commands below).

## CRITICAL TECHNICAL STATE (do NOT regress)

1. Xcode 27 / Swift 6.4 / objectVersion 77 pbxproj rules from the previous
   session all still apply:
   - Local package product object is `XCSwiftPackageProductDependency`
     (productName only — "XCLocalSwiftPackageProduct" is an UNKNOWN class and
     breaks project load).
   - Sources/Resources build phases are EMPTY; file membership comes from
     PBXFileSystemSynchronizedRootGroup ("App", "Watch", "WatchWidget",
     "AppUITests", "WatchUITests") via each target's fileSystemSynchronizedGroups.
   - Swift 6 strict concurrency throughout; 2026 SDK renames (viewContext,
     NSNumber @NSManaged, allowsExternalBinaryDataStorage,
     eventChangedNotification, etc.) already handled in code.
2. NEW this session — the iOS target now has the Watch-app wiring (IDs A1…186–189):
   - `Embed Watch Content` PBXCopyFilesBuildPhase, **dstPath = ""**,
     **dstSubfolderSpec = 13** (PlugIns). Xcode 26+ treats watchOS apps as
     Foundation extensions — they MUST be embedded in the parent app's PlugIns/
     (the legacy `$(CONTENTS_FOLDER_PATH)/Watch` + 16 layout now fails with
     "must be embedded in the parent app bundle's PlugIns directory").
   - Its PBXBuildFile (186) carries **`platformFilter = ios`** and the
     PBXTargetDependency (189) carries **`platformFilter = ios`** — required
     because the app target is multiplatform (a macOS build must not build or
     embed the watchOS app; without the filter the macOS build dies in
     ValidateEmbeddedBinary).
   - Do not "tidy" these filters away; do not revert dstSubfolderSpec to 16.
3. Widget target build settings include `MARKETING_VERSION = 0.1` and its
   Info.plist uses `$(MARKETING_VERSION)` — extension version must equal parent
   app version (was a 1.0 vs 0.1 mismatch warning).

## Signing / account state (current — this unblocks everything)

- The user's paid developer account is the SAME Apple ID as before → team ID
  stayed **2LFBN27WK8** (pbxproj already correct; no change was needed).
- The user has added the Apple ID to Xcode (⌘, → Accounts) on this Mac.
- Keychain: "Apple Development: JOSEPH TOMAS WOODS (VDWDUNC9R2)" cert (CN shows
  VDWDUNC9R2 but OU/team is 2LFBN27WK8 — trust the profile/codesign
  TeamIdentifier, i.e. 2LFBN27WK8).
- Provisioning profiles in ~/Library/Developer/Xcode/UserData/Provisioning
  Profiles/: development profiles for app/watch/widget (fetched 2026-09-26) +
  an older macOS dev profile. **App Store ("iOS Team Store …") profiles + a
  "Cloud Managed Apple Distribution" certificate were created by the export
  step** (cloud-managed = lives in Apple's cloud, not necessarily in the local
  keychain — that's why no local dist cert is needed).
- Real-device builds now work (provision a device in Xcode as usual).

## Xcode 27 CLI gotchas (learned this session — keep them in mind)

- Automatic signing over CLI requires **`-allowProvisioningUpdates`** on
  build/archive/export, otherwise "No profiles … Automatic signing is disabled".
- If no Apple ID is logged into Xcode GUI: "No Accounts: Add a new account in
  Accounts settings" — that's a user GUI step.
- `-exportArchive`:
  - `method` value **`app-store` is deprecated → use `app-store-connect`**.
  - **`-exportPath <dir>` CLI flag is now REQUIRED** (plist `destination` key
    alone is not enough; don't rely on it).
  - If the archive's `Info.plist` lacks the **ApplicationProperties** dict, the
    distribution flow classifies it as a "generic archive" and fails with the
    cryptic `exportOptionsPlist error for key "method" expected one {} but
    found app-store`. Fix: add ApplicationProperties to `.xcarchive/Info.plist`
    (keys: ApplicationPath, Architectures, CFBundleIdentifier,
    CFBundleShortVersionString, CFBundleVersion, SigningIdentity, Team).
    xcodebuild didn't write it for this archive; a `/usr/bin/python3` plistlib
    patch worked. (If a re-archive keeps missing it, re-apply the patch.)
- Exported .ipa for the watch-companion iOS app contains BOTH
  `Payload/NurseVault.app` (watch app nested in PlugIns/) and
  `Payload/NurseVault Watch.app` — that is the correct App Store layout; the
  file itself is named after the first archive product ("NurseVault Watch.ipa"),
  which is cosmetic only.

## Current state of the TestFlight push

- v0.1 build 1, version numbers unchanged (0.1 / 1) — nothing was ever uploaded
  before, so no version bump needed.
- iOS build: `archives/NurseVault-iOS-0.1.xcarchive` (gitignored) → exported to
  `build/export/export/NurseVault Watch.ipa` — verified: arm64, Cloud Managed
  Apple Distribution cert, "iOS Team Store Provisioning Profile" (Production
  CloudKit container) for app + watch app + widget. **Ready to upload.**
- Committed: 06ccf70 "TestFlight-ready alpha: embed Watch app in iOS target,
  camera/OCR import, UI tests" (includes last session's uncommitted work).
- The user chose **Option B**: they will upload from the Xcode GUI themselves.
- macOS: **DONE.** `archives/NurseVault-macOS-0.1.xcarchive` → exported to
  `build/export/export-mac/NurseVault.pkg` (847 KB) — verified: 3rd Party Mac
  Developer Installer cert, "Mac Team Store Provisioning Profile",
  Production CloudKit, sandbox. The `app-store-connect` export method worked
  for the Mac archive too (it produced the .pkg, which is the correct macOS
  App Store format; no separate `mac-application` method was needed).

## Commands (from the project folder)

```sh
# Signed device build (all three: swap scheme/destination; keep -allowProvisioningUpdates)
xcodebuild -project NurseVault.xcodeproj -scheme NurseVault \
  -destination "generic/platform=iOS" -configuration Release \
  -allowProvisioningUpdates build

# iOS archive
xcodebuild -project NurseVault.xcodeproj -scheme NurseVault \
  -destination "generic/platform=iOS" -configuration Release \
  -allowProvisioningUpdates -archivePath archives/NurseVault-iOS-0.1 archive

# iOS export (exportOptions.plist: method=app-store-connect,
# signingStyle=automatic, manageAppVersion=false, stripDebugSymbols=true,
# uploadSymbols=false, allowBetaAppConfiguration=true)
xcodebuild -exportArchive -archivePath archives/NurseVault-iOS-0.1.xcarchive \
  -exportOptionsPlist build/export/exportOptions.plist \
  -exportPath build/export/export -allowProvisioningUpdates

# Compile-only checks (no account needed): CODE_SIGNING_ALLOWED=NO
#   -destination "platform=macOS" | "generic/platform=iOS" | "generic/platform=watchOS" (watch scheme)
```

## Next steps (in order)

1. **macOS TestFlight — BUILT** (this session). Both archives are in the Xcode
   Archive Organizer (NurseVault — iOS, and NurseVault — macOS); the user
   uploads both via the GUI (Option B). Regenerate if ever stale:
   ```sh
   xcodebuild -project NurseVault.xcodeproj -scheme NurseVault \
     -destination "generic/platform=macOS" -configuration Release \
     -allowProvisioningUpdates -archivePath archives/NurseVault-macOS-0.1 archive
   xcodebuild -exportArchive -archivePath archives/NurseVault-macOS-0.1.xcarchive \
     -exportOptionsPlist build/export/exportOptions-mac.plist \
     -exportPath build/export/export-mac -allowProvisioningUpdates
   ```
   (`exportOptions-mac.plist` = same as the iOS one minus
   `allowBetaAppConfiguration`.)
2. **App Store Connect web steps (user):** for EACH app record:
   - My Apps → + → New App → **iOS**: "Nurse Vault", English, bundle ID
     `com.josephwoods.nursevault`, SKU `nursevault`.
   - (Mac, if we do it) **Mac** platform, same name/bundle ID, SKU
     `nursevault-mac` — same bundle ID on a different platform is allowed.
   - App Privacy tab: try **"I do not collect any data"** (data only ever lives
     in the user's own private iCloud/CloudKit). If TestFlight processing
     rejects it over the camera: declare **Camera → collected, not linked to
     identity, purpose "App Functionality"**.
   - App Age Rating tab: answer all "None" → 4+.
3. **Upload (user, Option B):** Xcode → Archive Organizer → select the archive →
   Distribute App → App Store Connect → (automatic signing) → Upload. The GUI
   handles re-signing with the distribution cert.
4. **After upload:** build shows "Preparing for Distribution" → passes TestFlight
   review (minutes to a day). Then in App Store Connect: TestFlight tab →
   assign build to the beta group (default "App Store Betas" or create one) →
   user installs the TestFlight app on a real iPhone (and the watch app lands on
   a paired watch automatically).
5. **Long-term (not needed for alpha):** App Store screenshots, app-specific
   marketing, public release. Nice-to-haves: watch complications polish,
   App Store Connect API key for fully automated uploads (skip GUI/altool).

## Watch for in a future session

- TestFlight build rejection reasons to expect: privacy label not filled (most
  likely first), or camera declaration. Neither requires a new build — metadata
  changes apply to already-uploaded builds; just re-trigger processing in ASC
  or wait.
- The watch app in the .ipa means TestFlight testers get it automatically on a
  paired watch — no separate watch ASC record needed.
- If the user ever wants standalone-watch distribution, that would be a separate
  record + archive of the watch scheme — but not needed now (it's a companion).
