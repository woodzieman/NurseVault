# Nurse Vault 2.0 — Full Project Rewrite Plan

## Live todo list

| Time (CDT) | Status | Next action |
|---|---|---|
| 2026-09-29 15:32 | Plan saved | Begin project.pbxproj rewrite |
| 2026-09-29 16:10 | Project file rewritten, schemes cleaned | Begin target validation/builds |
| 2026-09-29 16:51 | Addressing distribution errors | Fix Nesting, Info.plist and Orientation issues |
| 2026-09-29 19:05 | Distribution logs fully decoded; 5 of 6 iOS errors + macOS 90242 fixed & archive-verified | Find correct v110 `dstSubfolderSpec` for `Watch/` |
| 2026-09-29 19:30 | ⚠️ Spec-value test loop crashed Xcode GUI (PIF trap); pbxproj restored to safe state (13 + 16 only) | User reopens Xcode; capture Destination dropdown |
| 2026-09-29 19:45 | pbxproj restored + verified (lint OK, all fixes intact) | Nesting value, then final signed archive |

### Checklist

- [x] Save rewrite plan
- [x] Delete duplicate template `@main` files from `Watch/`
- [x] Rewrite `project.pbxproj` with the final 3-target architecture
- [x] Add shared schemes for all 3 targets
- [x] `xcodebuild -list` shows the intended 3 app targets and 3 shared schemes
- [x] Validate project and build targets (all 3 build; CLI archive succeeds)
- [x] Fix Widget extension package type (`XPC!` in `Support/Info.plist`; fixes 90364)
- [x] Resolve iPad multitasking orientation keys (4 orientations, both configs; fixes 90474)
- [x] Fix app category UTI (`public.app-category.medical`; fixes macOS 90242)
- [x] Fix Watch App icon (valid `idiom:watch` 1024 slot + real image + CFBundleIconName; fixes 90713/90391)
- [ ] Fix Watch App nesting: correct v110 `dstSubfolderSpec` for the `Watch/` subfolder (validator 90680 demands `Watch/`)
- [ ] Full archive re-verification (6-check list) after nesting fix
- [ ] macOS archive verification (category key present)
- [ ] Summarize remaining manual TestFlight steps

### Current status / next blocker

Completed:

- Removed the redundant template targets from the project graph:
  - `mac version`
  - `watch`
  - `watch Watch App`
  - `phone app new target`
- Rewrote the project into:
  - `Nurse Vault`
  - `Nurse Vault Watch`
  - `Nurse Vault Widget`
- Pointed targets at:
  - `App/`
  - `Watch/`
  - `WatchWidget/`
- Added `Support/` and `Packages/` groups.
- Added the local `NurseVaultCore` package to all three targets.
- Wired:
  - `Nurse Vault` embeds `Nurse Vault Watch` for iOS builds.
  - `Nurse Vault Watch` embeds `Nurse Vault Widget` in `PlugIns`.
- Replaced the old shared schemes with:
  - `Nurse Vault.xcscheme`
  - `Nurse Vault Watch.xcscheme`
  - `Nurse Vault Widget.xcscheme`
- Updated `xcschememanagement.plist`.

Validation so far:

- `xcodebuild -list` succeeds and shows:
  - Targets:
    - `Nurse Vault`
    - `Nurse Vault Watch`
    - `Nurse Vault Widget`
  - Schemes:
    - `Nurse Vault`
    - `Nurse Vault Watch`
    - `Nurse Vault Widget`
    - `NurseVaultCore`

Current blocker (2026-09-29 evening, supersedes the 16:51 note above):

The 16:51 widget package-resolution issue is obsolete — all three targets now build and the
CLI archive succeeds. The remaining distribution blocker is **Watch app nesting**:

Evidence (from the 5:07 PM GUI archive `~/Library/Developer/Xcode/Archives/2026-09-29/` and
its build task store):

- Upload validation returned 6 errors: 90713 (watch `CFBundleIconName` missing), 90391 (no
  icons for watch app), 90432 (unexpected file in `Frameworks/`), 90680 (watch app must be
  under `Watch/`), 90474 (no `UISupportedInterfaceOrientations`), 90364 (appex must be `XPC!`).
- **90680 settles the layout debate: the watch app must be under `Watch/`** — the earlier
  "PlugIns/ is required in Xcode 26+" theory was wrong.
- This project file is `objectVersion 110`. Measured subfolder behavior in that format:
  - spec `13` + `dstPath "$(CONTENTS_FOLDER_PATH)/Watch"` → `Frameworks/Nurse Vault.app/Watch/` (wrong)
  - spec `16` + `dstPath ""` → watch app copied to its own product dir (not embedded at all)
  - (In the older objectVersion-71 file, `13` + `""` produced `PlugIns/` — the v110 table
    is renumbered, so classic values cannot be reused blindly.)
- The correct v110 spec value for the `Watch/` subfolder is **still unknown**.

Fixed & verified this session (19:07 CLI archive + direct `actool` runs):

- `INFOPLIST_KEY_UISupportedInterfaceOrientations(_iPad)` (all 4 orientations) in both main
  target configs — present in the archived iOS Info.plist ✓
- `LSApplicationCategoryType = public.app-category.medical` (was `public.medical-app`) ✓
- `Support/Info.plist` (widget): `CFBundlePackageType = XPC!` ✓
- Watch target: `INFOPLIST_KEY_CFBundleIconName = AppIcon` + `Watch/Assets.xcassets/AppIcon.appiconset`
  now holds a real 1024×1024 image with slot `{"idiom": "watch", "size": "1024x1024"}` (+
  `ios-marketing` slot). `actool --platform watchos` now emits `CFBundleIcons/CFBundleIconName` ✓
  (Note: `"platform": "watch"` is rejected by Xcode 27 `actool`: "Unknown platform value".)

⚠️ Xcode crash incident (19:26–19:30):

- A rapid test loop rewrote the embed phase `dstSubfolderSpec` through values 0, 11, 12, 14, 15,
  18 while the user's Xcode was open. Xcode 27 **crash-loops** on at least one of those values
  (fatal trap in `PBXCopyFilesBuildPhase.pifRepresentation`; value 18 also killed the CLI build
  service, exit 133).
- The pbxproj was restored to the last GUI-proven-safe state: embed phase = spec `16` +
  `dstPath ""` (file now contains only values 13 and 16; `plutil -lint` OK; all other fixes
  intact). The user's Xcode should open normally again.
- **RULE: never rewrite `dstSubfolderSpec` values in bursts, never use values ≥ 17, and never
  edit the pbxproj's copy phases while the user's Xcode is open.**

Next steps (in order):

1. User reopens Xcode (crash loop should be gone with the restored file).
2. Find the v110 `Watch/` spec value, safely:
   - Preferred: with the project open, select the `Embed Watch Content` phase in the main
     target's Build Phases and screenshot the **Destination:** dropdown (item order reveals
     the name→value mapping for v110 files).
   - Fallback (Xcode CLOSED): change the value ONE at a time (14, 15, then 1–9; avoid ≥17),
     archive (`xcodebuild -project "Nurse Vault.xcodeproj" -scheme "Nurse Vault" -destination
     "generic/platform=iOS" -configuration Release CODE_SIGNING_ALLOWED=NO -archivePath … archive`),
     check where the watch app lands in the archive bundle, restore the safe value after each test.
   - Success = `Nurse Vault.app/Watch/Nurse Vault Watch.app` inside the archive bundle.
3. Full re-verification of the archived bundle (6-check list, see session handoff doc).
4. macOS archive check (category key).
5. User uploads via Xcode GUI (Distribute App → App Store Connect).

---

## Status (2026-10-02, late morning) — fastlane upload WORKING; v2.4 build 3 on ASC

The root project now uploads end-to-end via `fastlane upload` (full gotcha list in
SESSION_HANDOFF.md). Nurse Vault **2.4 / build 3** is in App Store Connect — version
record PREPARE_FOR_SUBMISSION, builds VALID + APP_STORE_ELIGIBLE — and ready to
distribute on TestFlight. The 2.0 project remains the fallback path but is no longer
needed for uploads. Remaining metadata fix before review: add a copyright year
(precheck warning).

---

## Status (2026-10-02) — ROOT CAUSE FOUND & FIXED: SKIP_INSTALL + Watch/ layout

The missing `ApplicationProperties` is **solved** in the root project
(commit `0ff2d5c`). The 10/1 SDKROOT theory below is **DEAD**.

### Root cause (decoded from Xcode's own binary)

Disassembled IDEDistribution.framework (`+[IDEArchivedApplication
soleArchivedContentRelativePathInDirectory:]` +
`+[IDEArchivedContent fillArchivedContentInfoInArchiveInfoDictionary:…]`):

- The archiver lists `Products/Applications/`, keeps entries that are not
  `OnDemandResources` and don't start with `.`, and requires **exactly one**
  of them, whose path extension must be `app`. Anything else → nil.
- When every content class returns nil the caller writes **no
  ApplicationProperties at all — silently, no error**. That is exactly what a
  "generic archive" without AppProps is.
- The root project's watch target lacked **`SKIP_INSTALL = YES`**, so
  xcodebuild archived `NurseVault Watch.app` as a SECOND top-level product →
  count = 2 → nil. The 2.0 project's watch target has SKIP_INSTALL=YES — the
  one real difference between the working and broken archives (SDKROOT,
  schemes, signing, Xcode version all ruled out).

### Fix applied to `NurseVault.xcodeproj` (mirrors the proven 2.0 project)

1. Watch target Debug + Release: **`SKIP_INSTALL = YES`**.
2. "Embed Watch Content" phase: `dstPath = "$(CONTENTS_FOLDER_PATH)/Watch"`,
   `dstSubfolderSpec = 16` (was `""` + 13 → PlugIns/) — also the layout
   validator **90680** demands.

Verified with an unsigned CLI archive (`CODE_SIGNING_ALLOWED=NO`):
Info.plist now carries ApplicationProperties
(`ApplicationPath = Applications/NurseVault.app`, bundle ID, version),
Products/Applications/ holds exactly one app, watch at
`NurseVault.app/Watch/NurseVault Watch.app`, widget in its PlugIns/. Also
committed: TestPlan.xctestplan removed from the app's Resources phase
(`e2d91be`) — it was being bundled inside NurseVault.app.

### Outstanding (updated)

- [ ] User: GUI-archive “NurseVault” (iOS destination) + Distribute — should
      work now; report the Organizer result
- [x] ~~If root export still fails → drop macosx~~ — no longer needed;
      macosx stays in SUPPORTED_PLATFORMS
- 2.0 project remains a proven fallback path if anything regresses.

---

## Status (2026-10-01) — export root cause found; 2.0 watch aligned

### Root app export — diagnosis (archive forensics)

The user still can't export the root project. Checked
`~/Library/Developer/Xcode/Archives`:

- Root “NurseVault” GUI archives (9/30 ×2, 10/1 7:38 AM) are **missing the
  `ApplicationProperties` key** in the archive Info.plist → the Organizer
  classifies them as a generic archive and the Distribute flow refuses
  (the known-good v0.1 archives from 9/26 all have it).
- The bundle layout is perfect: `NurseVault.app/PlugIns/NurseVault
  Watch.app`, widget in the watch app's PlugIns; the watch app's
  cloud-managed profile **already includes the App Group**
  (`group.com.josephwoods.nursevault`).
- The only app-target config difference vs the 2.0 project (whose GUI
  archives DO carry ApplicationProperties + a Distributions record): the
  root app target used `SDKROOT = iphoneos`, the 2.0 used `SDKROOT = auto`
  (both were multiplatform). → **Root app target is now `SDKROOT = auto`**
  (macosx left in `SUPPORTED_PLATFORMS` for now). Unsigned builds pass.
- Fallback if it still fails: drop `macosx` from the root app target (same
  as the 2.0 project).

### 2.0 — same watch functionality as the root

- Watch target `TARGETED_DEVICE_FAMILY` → `"4,5,7,8,10,11,12,13,14,15"`
  (was `4`) — matches root, current-generation watches supported.
- Widget `WATCHOS_DEPLOYMENT_TARGET` → `11.0` (was 10.0) — matches root.
- Everything else already matched after the 9/30 sync (all sources,
  App Group entitlements, watch app 10.0 deployment, embed layout).
- Unsigned app + watch builds pass; committed in the 2.0 repo.
- The 2.0 project's 9/30 GUI archive proves the pipeline works end-to-end:
  `Nurse Vault.app/Watch/Nurse Vault Watch.app` layout + ApplicationProperties
  + Distributions record. **The 2.0 project is the ready export path** — a
  fresh archive of “Nurse Vault” carries folders + the App Group widget fix.

### Outstanding

- [ ] User: GUI-archive the root “NurseVault” (SDKROOT=auto now) and/or the
      2.0 “Nurse Vault” project; report the Organizer/export result
- [ ] If root export works → decide which project stays canonical
- [ ] If root export still fails → drop `macosx` from the root app target

---

## Status (2026-09-30, evening) — 2.0 RESURRECTED + root export fix

### `nursevault 2.0/Nurse Vault/` is active again (user decision)

The 2.0 project is the full-app path again (all 3 targets: app + watch +
widget). It is being synced to the root project's current sources so it has
everything the root gained since the Sep 28 fork:

- **App (`App/`)**: `CameraImport`, `DocDetailView`, `DocListView`,
  `ImportView`, `RootView` ← root `Sources/iOS` (save-to-folder on every
  import flow, folder import + drag & drop, `VaultListView` drill-down,
  store-reset handling).
- **Package (`Packages/NurseVaultCore`)**: `VaultModels` (VaultFolder),
  `Library` (`importFolder` + `storeWasReset`), `FileSupport` (folder
  helpers), `Search`, `StoreLocation` (watch App Group summary) ← root.
- **Watch changes (the widget fix)**: App Group
  `group.com.josephwoods.nursevault` added to
  `Watch/WatchEntitlements.entitlements` + new
  `WatchWidget/WatchWidget.entitlements` + `CODE_SIGN_ENTITLEMENTS` on the
  widget target. Without the App Group the widget cannot read the watch
  app's summary (separate sandbox containers) — the App Group **is** the
  fix. This is the only signing-adjacent change; signing style, team, bundle
  IDs, versions all untouched.
- **Mac removed** from the 2.0 app target for now (user: "make the 2.0
  without the mac app for now"): `SUPPORTED_PLATFORMS = "iphoneos
  iphonesimulator"`, `MACOSX_DEPLOYMENT_TARGET` + macOS runpath line gone.
  (`ENABLE_HARDENED_RUNTIME` left in — inert on iOS, it's a signing flag.)

Export consequence for the user: first signed build/archive of the 2.0
project will make automatic signing register the App Group and refresh the
cloud profiles. The 2.0 project shares the root project's bundle IDs + team,
so it is the same profiles the root export uses; a CLI export needs
`-allowProvisioningUpdates`.

### Root project — export experiment

User: root app "refuses to export, probably because it's mac as well".
Experiment (temporary): remove the 3 UI test targets
(`NurseVaultUITests`, `NurseVaultMacUITests`, `NurseVaultWatchUITests` +
their 2 shared schemes). **Widget stays** (user: "the widget is fine").
Kept: `NurseVault` + `NurseVault Watch` + `NurseVault Watch Widget`.
Fallback if the export still fails: drop `macosx` from the app target's
`SUPPORTED_PLATFORMS` (same change as the 2.0 project). Revert: `git
revert <experiment commit>` — checkpoint was committed before the change.

### Outstanding (as of the evening sync)

- [x] 2.0 sync done + verified: all 10 source files byte-identical to root,
      App Group entitlements in place, macosx gone from the app target,
      `plutil -lint` OK, unsigned Debug builds of `Nurse Vault` +
      `Nurse Vault Watch` (widget embedded) pass. Committed in the 2.0 repo
      ("Resurrect 2.0: sync all sources from root project…").
- [x] Root export experiment done + verified: 3 UI test targets removed
      (commit `9fbad3e`), unsigned builds pass. **User: try the export now.**
- [ ] User: archive + export the root app (2.4/3) and report the outcome
- [ ] If the root export still fails → remove `macosx` from the root app
      target, or restore the targets (`git revert 9fbad3e`) and use the 2.0
      project's export instead (same bundle IDs/team; first export registers
      the App Group via automatic signing)

---

## Status update (2026-09-30, Bionic session) [superseded by the section above]

### Canonical tree — DECIDED: root project (2026-09-30)

- **Root** `NurseVault.xcodeproj` (objectVersion 71, single multiplatform
  app target + Watch + Widget) is the canonical Nurse Vault 2.0 project.
  Folder feature (`8bdd0d3`) + version 2.0 + watch distribution keys
  (`910498a`) are committed there; unsigned Release builds pass.
- **`nursevault 2.0/Nurse Vault/`** is **retired** (left on disk; safe to
  delete). Its v110 pbxproj now carries the verified embed value (16 +
  `$(CONTENTS_FOLDER_PATH)/Watch`) in case it's ever resurrected. Its
  exported .ipa was built from stale Sep 28 code (no folder feature) —
  deleted; do NOT use it.
- The user does all signing/building/upload themselves.

### dstSubfolderSpec research result (answers the 19:05/19:45 blocker)

Authoritative source: **Xcode 27's own build-system specs**
(`/Applications/Xcode.app/.../SWBBuildService.../XCBSpecifications.../*.xcspec`):

- `10` = Frameworks ("Embed Frameworks" / "Embed Libraries")
- `13` = **Plug-ins** ("Embed PlugIns", literal `// Plug-ins` comment) → appex
- `16` = **explicit DstPath only** — injected for watch app embedding as
  `DstSubFolderSpec = 16` + `DstPath = "$(CONTENTS_FOLDER_PATH)/Watch"`
  (same pattern for App Clips: 16 + `$(CONTENTS_FOLDER_PATH)/AppClips`)

So the canonical v110 "Embed Watch Content" is **16 +
`$(CONTENTS_FOLDER_PATH)/Watch`**. The 2.0 project's phase was 16 + `""`, which
measured to *no embedding at all* (7:08/8:16/8:19 PM archives contain no
watch app) — that is exactly "build succeeds, watch app missing in TestFlight".
The widget phase (13 + `""`) is already the canonical Plug-ins placement.

Caveat: an XcodeGen issue (Apr 2026, Xcode 26.4) reports an *install-time*
"Foundation extension must be in PlugIns" failure for the Watch/ layout on
modern project files. Xcode 27 still injects Watch/, and the Sep 29 upload
validator (90680) pointed the other way. Resolve empirically: set the phase
to 16 + `$(CONTENTS_FOLDER_PATH)/Watch`, archive, upload-validate, install.
NEVER edit copy phases while the user's Xcode is open (crash-loop rule).

**RESOLVED (2026-09-30, Xcode closed, single careful edit):**

- Applied `16` + `"$(CONTENTS_FOLDER_PATH)/Watch"` to the 2.0 project's
  "Embed Watch Content" phase (backup of the prior file kept in /tmp).
- Unsigned iOS Release archive: `Nurse Vault.app/Watch/Nurse Vault Watch.app`
  ✓ and `…/Nurse Vault Watch.app/PlugIns/Nurse Vault Widget.appex` ✓
  — the exact layout validator 90680 demanded. **The spec value was never the
  problem (16 was correct); the missing `dstPath` was.**
- Signed archive (`-allowProvisioningUpdates`, Apple Development identity)
  + `-exportArchive` (method `app-store-connect`, automatic, team 2LFBN27WK8):
  **`build/export/Nurse Vault.ipa`** — v2.0 build 3 (ASC already knew builds
  1–2 of com.josephwoods.nursevault from the v0.1 era, so the auto-increment
  landed on 3 — proof v0.1 builds exist in ASC), Apple Distribution cert on
  all three bundles, three "iOS Team Store Provisioning Profile" profiles.
- `build/` added to the 2.0 folder's .gitignore.
- The open risk is only the Xcode-26-era install-time PlugIns check: it will
  show up when the build is installed via TestFlight. If it fails on install,
  the fallback is `13` + `""` (Plug-ins) — but then re-verify upload
  validation, since 90680 pointed at Watch/.

### Fixed along the way (all committed in 8bdd0d3 unless noted)

- `Library.swift`: `#if !os(watch)` → `#if !os(watchOS)` (was a compile error),
  removed duplicate `docs(in:)`, cycle guard in `moveFolder`, folder helpers.
- One-time store reset when a v0.1-era store can't open under the 2.0 model
  (+ `storeWasReset` surfaced as a one-time alert in RootView).
- `Support/Info.plist`: reverted a working-tree regression `XPC!` → `XPCl`
  (restored the known-good `XPC!` from HEAD via git — flagging for awareness).
- `App/` and `Sources/iOS/` re-synchronized (app target builds the Sources/ copy).

### Still open (user action required)

1. ~~Close Xcode / embed experiment~~ — done (see above).
2. **Upload `nursevault 2.0/Nurse Vault/build/export/Nurse Vault.ipa`** —
   either fix the API key (re-verify Issuer ID / regenerate; JWT side is
   proven fine) and upload via the ASC API, or Xcode GUI → Organizer →
   Distribute App → App Store Connect. Then confirm the watch app lands on a
   paired Apple Watch via TestFlight.
3. Canonical-tree decision (root project vs 2.0 folder) — see above.

---

Target project:

`nursevault 2.0/Nurse Vault/Nurse Vault.xcodeproj/project.pbxproj`

This plan rewrites the Xcode project file into the final TestFlight-ready architecture:

1. `Nurse Vault` — iPhone + iPad + Mac app
2. `Nurse Vault Watch` — Apple Watch app
3. `Nurse Vault Widget` — Apple Watch complication / widget extension

The rewrite intentionally removes the redundant template targets from the project graph:

- `mac version`
- `watch`
- `watch Watch App`
- `phone app new target`

Their folders remain on disk unless they contain duplicate template entry points that would break the real Watch target.

---

## 1. Final source layout

| Folder | Purpose |
|---|---|
| `App/` | Real iPhone/iPad/Mac app sources |
| `Watch/` | Real Apple Watch app sources |
| `WatchWidget/` | Real Apple Watch complication/widget sources |
| `Support/` | Widget `Info.plist` |
| `Packages/NurseVaultCore/` | Shared local Swift package |
| `Nurse Vault/` | Old stub folder, kept for browsing only, not compiled |

Final Xcode navigator groups:

- `App/`
- `Watch/`
- `WatchWidget/`
- `Support/`
- `Packages/`
- `Nurse Vault/`
- `Products/`

Final products:

- `Nurse Vault.app`
- `Nurse Vault Watch.app`
- `Nurse Vault Watch Widget.appex`

---

## 2. Target architecture

### Nurse Vault

- Product: `Nurse Vault.app`
- Bundle ID: `com.josephwoods.nursevault`
- Source folder: `App/`
- Platforms: iPhone, iPad, Mac
- Deployment targets:
  - iOS 17.0
  - macOS 14.0
- Marketing version: `2.0`
- Build version: `1`
- SDK: `auto`
- Supported platforms: `iphoneos iphonesimulator macosx`
- Device family: `1,2`
- Entitlements: `App/NurseVault.entitlements`
- Camera usage description:
  `Nurse Vault uses the camera to photograph documents and scan them for on-device text recognition.`
- Display name: `Nurse Vault`
- Embeds: `Nurse Vault Watch.app` for iOS builds only
- Package dependency: `NurseVaultCore`

### Nurse Vault Watch

- Product: `Nurse Vault Watch.app`
- Bundle ID: `com.josephwoods.nursevault.watchkitapp`
- Source folder: `Watch/`
- Platform: watchOS
- Deployment target: watchOS 10.0
- Marketing version: `2.0`
- Build version: `1`
- SDK: `watchos`
- Supported platforms: `watchos watchsimulator`
- Device family: `4`
- Entitlements: `Watch/WatchEntitlements.entitlements`
- Companion app bundle ID: `com.josephwoods.nursevault`
- Skip install: `YES`
- Embeds: `Nurse Vault Watch Widget.appex` in `PlugIns`
- Package dependency: `NurseVaultCore`

### Nurse Vault Widget

- Product: `Nurse Vault Watch Widget.appex`
- Bundle ID: `com.josephwoods.nursevault.watchkitextension`
- Source folder: `WatchWidget/`
- Platform: watchOS
- Deployment target: watchOS 10.0
- Marketing version: `2.0`
- Build version: `1`
- SDK: `watchos`
- Supported platforms: `watchos watchsimulator`
- Device family: `4`
- Skip install: `YES`
- Info.plist: `Support/Info.plist`
- Generate Info.plist: `NO`
- Runpath search paths:
  - `$(inherited)`
  - `@executable_path/Frameworks`
  - `@executable_path/../../Frameworks`
- Package dependency: `NurseVaultCore`

---

## 3. Build phases

### Nurse Vault

- Sources
- Frameworks
  - `NurseVaultCore`
- Resources
- Embed Watch Content
  - `Nurse Vault Watch.app`
  - Destination: `$(CONTENTS_FOLDER_PATH)/Watch`
  - Platform filter: `ios`
- Target dependency:
  - `Nurse Vault Watch` with `ios` platform filter

### Nurse Vault Watch

- Sources
- Frameworks
  - `NurseVaultCore`
- Resources
- Embed Foundation Extensions
  - `Nurse Vault Watch Widget.appex`
  - Destination: `PlugIns`
- Target dependency:
  - `Nurse Vault Widget`

### Nurse Vault Widget

- Sources
- Frameworks
  - `NurseVaultCore`
- Resources

No app target should embed the widget directly. The widget is embedded only by the Watch app.

---

## 4. Package integration

Add a local Swift package reference:

`Packages/NurseVaultCore`

Package product:

`NurseVaultCore`

Attach that product to:

- `Nurse Vault`
- `Nurse Vault Watch`
- `Nurse Vault Widget`

The package already declares:

- iOS 17
- macOS 14
- watchOS 10

---

## 5. File cleanup

The real Watch source folder currently contains duplicate template files:

- `Watch/watchApp.swift`
- `Watch/ContentView.swift`

These create a second `@main` entry point and must be removed from disk before the rewrite is built.

Files that are intentionally kept on disk:

- `Nurse Vault/`
- `mac version/`
- `watch/`
- `watch Watch App/`
- `phone app new target/`

Only their Xcode target references are removed from the rewritten project.

---

## 6. pbxproj rewrite details

The rewritten `project.pbxproj` will:

- Preserve the project object ID.
- Preserve the existing project-level Debug/Release build settings.
- Keep object version `110` and preferred project object version `77`.
- Replace all native targets with the final three targets.
- Add synchronized folder groups for:
  - `App`
  - `Watch`
  - `WatchWidget`
- Add normal groups for:
  - `Support`
  - `Packages`
- Keep the old `Nurse Vault` synchronized folder for browsing, but not associate it with any target.
- Add product file references:
  - `Nurse Vault.app`
  - `Nurse Vault Watch.app`
  - `Nurse Vault Watch Widget.appex`
- Add package reference and package product dependency.
- Add copy-files phases:
  - `Embed Watch Content`
  - `Embed Foundation Extensions`
- Add target dependencies:
  - `Nurse Vault` depends on `Nurse Vault Watch` for iOS
  - `Nurse Vault Watch` depends on `Nurse Vault Widget`

---

## 7. Schemes

Create shared schemes:

- `Nurse Vault.xcscheme`
- `Nurse Vault Watch.xcscheme`
- `Nurse Vault Widget.xcscheme`

Update:

`xcuserdata/josephwoods.xcuserdatad/xcschemes/xcschememanagement.plist`

so the scheme dropdown lists all three targets.

The widget scheme is for building the extension; the widget is not uploaded independently.

---

## 8. Validation

After the project rewrite:

1. Lint the project file if possible.
2. Run:
   - `xcodebuild -list`
3. Build the three targets:
   - `Nurse Vault` for iOS simulator/device as appropriate
   - `Nurse Vault Watch` for watchOS simulator/device as appropriate
   - `Nurse Vault Widget` for watchOS simulator/device as appropriate
4. Confirm:
   - No duplicate `@main` errors in the Watch target.
   - `NurseVaultCore` resolves in all three targets.
   - The Watch app is embedded in the iPhone app for iOS builds.
   - The widget is embedded in the Watch app.
   - No redundant template targets appear in the scheme list.

---

## 9. Manual TestFlight steps after successful builds

1. Select `Nurse Vault`.
2. Choose `Any iOS Device (arm64)`.
3. Product → Archive.
4. Distribute App → App Store Connect → Upload.
5. Repeat for `Nurse Vault Watch` using `Any Apple Watch Device`.
6. Do not upload the widget separately.
7. In App Store Connect, attach both builds to TestFlight and submit for beta review.
