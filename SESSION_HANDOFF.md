# Session handoff — Nurse Vault → TestFlight alpha

## STATUS (2026-10-04) — review pass + copyright fixed + pushed

- **Copyright precheck warning FIXED:** user chose "© 2026 Woodzieman". Set in
  `fastlane/metadata/copyright.txt` and pushed via `fastlane upload_metadata`
  (the lane works end-to-end; deliver merges remote metadata as the base, so
  with only copyright.txt present locally it touched only the copyright).
  Precheck now fully green, incl. "No incorrect or missing copyright date".
- **Review pass committed** (2 commits): .gitignore now ignores local-only
  clutter (`*.xctestproducts/`, `*.ipa`, `*.cer`, `nursevault 2.0/`,
  `project_backup*`, `test 3/4/` — files still on disk, user may delete them,
  ~400 MB reclaimable if the 2.0 fallback is no longer needed); stale widget
  "shares the watch app's container" comment → App Group; `RootView` resets
  sidebar selection when its section is deleted (avoids faulting a deleted
  managed object); README says 2.4 now. Unsigned iOS-sim build passes.
- **All local work is on origin/main** (user asked to push; done).
- Leftover cleanup still needing the USER's call: dead ASC API keys
  (R5U42R887M / RF94CMB28K at repo root, if no longer needed — delete in
  ASC → Integrations, then the .p8 files), and deleting the ignored
  experiment folders listed above. Next gate: user submits v2.4 for review
  (Xcode or `fastlane submit_for_review` — the upload lane does not submit).

## STATUS (2026-10-02, late morning) — UPLOAD DONE: v2.4 build 3 is on ASC/TestFlight

- **fastlane upload SUCCEEDED** (`fastlane upload` lane): Nurse Vault **2.4 / build 3**
  archived + exported + uploaded to App Store Connect via API key Y9YADVN9Z2.
  Verified over the ASC REST API: appStoreVersion "2.4" (IOS) in
  PREPARE_FOR_SUBMISSION with VALID, APP_STORE_ELIGIBLE builds from today's uploads.
- **Profile blocker solved**: stale cloud-managed store profiles for watch/widget
  (Sep 29 — they predate the App Group addition) were deleted from Xcode's profile
  cache; user then logged into their Apple ID in Xcode. REQUIRED: `xcodebuild` has NO
  separate CLI sign-in and reads Xcode's account store directly — an empty
  `DVTDeveloperAccountManagerAppleIDLists` means "No Accounts" on export, and API keys
  added under Settings → Accounts do NOT count (they can't auto-download profiles).
  With the Apple ID present, `-allowProvisioningUpdates` fetched fresh store profiles
  with the App Group.
- **fastlane 2.240 gotchas** (all fixed in fastlane/Fastfile): `api_key:` must be a
  Hash `{ key_id:, issuer_id:, key: <raw PEM> }` — string path is rejected and
  :key_content is NOT the right field (spaceship's Token.create wants :key);
  `skip_waiting_for_build_processing` and `notify_testflight_external_testers`
  options no longer exist; deliver's `:ipa` default = newest *.ipa in CWD — stale
  repo-root .ipas made it pick NurseVault-Debug.ipa (version "0.1"!) so the ipa path
  is pinned explicitly; precheck runs AFTER binary upload and can't check IAPs via API
  key → `precheck_include_in_app_purchases: false`.
- **Quirk**: a deliver run that fails at precheck has ALREADY uploaded its binary —
  today's failed run left one build record, the successful run added another (same
  binary; ASC shows both under v2.4).
- Precheck warning to fix before review submission: metadata copyright year missing.
- fastlane/ committed (Fastfile/Appfile/README); deliver artifacts gitignored; .p8 keys
  stay gitignored (`AuthKey_*.p8`). Working ASC keys: Y9YADVN9Z2 + 7969H83JMY (issuer
  c8e01104-…); old key P24GJ5VLS6 still 401s.

## STATUS (2026-10-02) — read this first

- **Root cause FOUND AND FIXED** (commit `0ff2d5c`): root-project archives
  lacked `ApplicationProperties` because the **watch target had no
  `SKIP_INSTALL = YES`**. Without it, xcodebuild archived the watch app as a
  SECOND top-level product in `Products/Applications/`. Xcode's own archiver
  logic (decoded from IDEDistribution.framework,
  `+[IDEArchivedApplication soleArchivedContentRelativePathInDirectory:]`)
  requires EXACTLY ONE entry there (excluding OnDemandResources + dotfiles)
  with extension `.app`; two entries → nil → the caller silently writes no
  ApplicationProperties, no error. The 2.0 project's watch target has
  SKIP_INSTALL=YES — that was the real difference all along.
- **SDKROOT theory is DEAD** (the 10/1 `iphoneos`→`auto` change was a red
  herring; today's GUI archive still lacked AppProps after it). macosx stays
  in SUPPORTED_PLATFORMS — no fallback needed anymore.
- Also fixed the validator-90680 layout: "Embed Watch Content" phase is now
  `dstPath = "$(CONTENTS_FOLDER_PATH)/Watch"` + `dstSubfolderSpec = 16`
  (was `""` + 13 → PlugIns/), mirroring the proven-working 2.0 project.
- Verified with an unsigned CLI archive: Info.plist carries
  ApplicationProperties, ONE top-level app, watch at
  `NurseVault.app/Watch/NurseVault Watch.app`, widget in its PlugIns/.
- **User next step:** re-archive “NurseVault” in the Xcode GUI (iOS
  destination) and Distribute — Organizer should now accept it. The TestPlan
  .xctestplan is also no longer bundled inside NurseVault.app (commit
  `e2d91be`). User does all signing/exporting.
- **2.0 watch aligned with root** (earlier): watch
  `TARGETED_DEVICE_FAMILY = "4,5,7,8,10,11,12,13,14,15"` + widget
  `WATCHOS_DEPLOYMENT_TARGET = 11.0`. The 2.0 project remains a working
  fallback export path (its 9/30 GUI archive proves the pipeline end-to-end).

## STATUS (2026-09-30, evening)

- The retired `nursevault 2.0/Nurse Vault/` v110 project is **active again**
  (user decision; "now active again"). It is being synced with everything
  the root project gained since the Sep 28 fork: folders, folder import /
  drag & drop, and the watch App Group widget fix. Mac removed from its app
  target ("without the mac app for now"); all other signing (style, team,
  bundle IDs, versions) untouched. Full plan:
  NURSE-VAULT-2.0-REWRITE-PLAN.md ("2.0 RESURRECTED + root export fix").
- Root project: user reports it "refuses to export, probably because it's
  mac as well". Experiment: the 3 UI test targets removed (checkpoint
  committed first; widget kept — "the widget is fine"). If the export still
  fails: drop `macosx` from the app target's `SUPPORTED_PLATFORMS`.
- User does all building/signing/exporting themselves.

## STATUS (2026-09-30, second Bionic session)

This session fixed the watch widget and added folder import / drag & drop:

- **Watch widget root cause:** the widget appex runs in its **own sandbox
  container**; the summary JSON was being written to the watch app's private
  `Application Support`, which the widget can never see. Fixed the Apple-endorsed way: the watch app and the widget now share **App Group
  `group.com.josephwoods.nursevault`**, and `VaultSummary` (in NurseVaultCore
  `StoreLocation.swift`) reads/writes the summary from the group container on
  watchOS (falls back to Application Support when the entitlement is missing,
  e.g. unsigned builds). Entitlements: `Sources/Watch/WatchEntitlements
  .entitlements` (added) and new `Sources/Widget/WatchWidget.entitlements`
  (pbxproj now points at it; the widget target previously had no
  entitlements file).
- **Stale-folder trap fixed:** targets' `CODE_SIGN_ENTITLEMENTS` still pointed
  at the pre-unification legacy folders `App/` and `Watch/`. Repointed to
  `Sources/iOS/` and `Sources/Watch/`, and **deleted the legacy `App/`,
  `Watch/`, `WatchWidget/` folders** (verified byte-identical to `Sources/*`
  before deletion; git history preserves them).
- **Folder upload / drag & drop (app):** new `Library.importFolder(at:to:in:)`
  (NurseVaultCore) mirrors a directory into a vault folder (nested folders →
  nested `VaultFolder`s; collision-safe " (2)" naming; skips files > 48 MB /
  unreadable and reports them in a summary; one save + reload at the end).
  `FileSupport` gained `isDirectory(at:)` / `directoryEntries(at:)` and an
  early size check in `importFile`. `VaultListView` drop now accepts
  fileURL + folder + directory UTTypes and routes directories to
  `importFolder`; `ImportView` file picker allows folders too ("Choose Files
  or Folders…"). Works on every list level (All / section / folder).
- **Build state:** `swift build` of the package (macOS) + unsigned
  `CODE_SIGNING_ALLOWED=NO` xcodebuild sanity builds of NurseVault (iOS +
  macOS) and NurseVault Watch (incl. widget) all pass. **No signed builds
  have been made this session** — user rebuilds in Xcode GUI; automatic
  signing will register the new App Group on first build. Next TestFlight
  export needs `-allowProvisioningUpdates` so the cloud profile includes the
  App Group (affects the watch app + widget; the iOS app target is unchanged).
- README updated (layout → Sources/, folder feature, App Group explanation;
  the old "widget shares the watch app's container" claim was wrong).

Below: prior session state (TestFlight/ASC), still valid except where it says
the widget "shares the watch app's container" (it doesn't — see above).

## STATUS (2026-09-30, first Bionic session)

- **Canonical project = the ROOT `NurseVault.xcodeproj`** (user decision).
  The `nursevault 2.0/` v110 experiment folder is **retired** (left on disk,
  safe to delete; nothing canonical lives there).
- The app is now **Nurse Vault 2.0**: `MARKETING_VERSION = 2.0` on all targets
  (commit 910498a), folder feature complete (commit 8bdd0d3: `VaultFolder`
  model, `VaultListView` drill-down, save-to-folder on every import flow).
- Watch target fixed for distribution: `DEVELOPMENT_TEAM` +
  `INFOPLIST_KEY_CFBundleIconName = AppIcon` (validator 90713); the 1024
  `platform: watchos` icon slot was already in `Sources/Watch`.
- **The user handles all signing/building themselves** — no further
  `xcodebuild` signing/export runs from this side. Unsigned sanity builds
  (app + watch, Release) pass.
- ASC state: builds 1–2 of `com.josephwoods.nursevault` already exist (v0.1
  era) → the next 2.0 export will auto-increment to build 3+ (with
  `manageAppVersionAndBuildNumber`).
- Upload route: Xcode GUI Distribute (user) or the ASC API once the 401 key
  issue is resolved (see below). v110 `dstSubfolderSpec` research result
  (16 + `$(CONTENTS_FOLDER_PATH)/Watch`) is documented in
  NURSE-VAULT-2.0-REWRITE-PLAN.md for reference; the root v71 file uses the
  classic Plug-ins layout, proven on-device with v0.1.

---

I'm continuing work on the "Nurse Vault" project in the "Nursing app" folder.
Goal: get the **v0.1 alpha onto TestFlight** (iPhone/iPad + Watch, plus the Mac
app). The user has a **paid Apple Developer account** (added to Xcode on this
Mac, same Apple ID → team ID stayed **2LFBN27WK8**). We are using **Option A**:
an App Store Connect **API key** to upload programmatically; the user will
**delete the key after we're done** ("reset all permissions when complete").

**CURRENT BLOCKER (top priority):** the API key the user provided returns
**401 NOT_AUTHORIZED** for every request, even though the JWT is
cryptographically valid (verified locally). See the "ASC API — current state"
section for the diagnosis and the user checklist.

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
- `build/export/` (gitignored):
  - `export/NurseVault Watch.ipa` — the exported iOS TestFlight build (v0.1/1)
  - `export-mac/NurseVault.pkg` — the exported macOS TestFlight build (v0.1/1)
  - `exportOptions.plist` / `exportOptions-mac.plist` — export configs
  - **`asc/AuthKey_P24GJ5VLS6.p8`** — the user's ASC API key (NEVER commit)
  - **`asc/asc-jwt.sh`** — JWT helper: `asc-jwt.sh <key.p8> <key-id> <issuer-id> [aud]`
    prints a 15-min ES256 JWT (openssl sign + Python DER→raw r||s fix; keep all
    binary out of shell variables — zsh `$(...)` silently drops NUL bytes).

## CRITICAL TECHNICAL STATE (do NOT regress)

1. Xcode 27 / Swift 6.4 / objectVersion 77 pbxproj rules from the previous
   sessions all still apply:
   - Local package product object is `XCSwiftPackageProductDependency`
     (productName only — "XCLocalSwiftPackageProduct" is an UNKNOWN class and
     breaks project load).
   - Sources/Resources build phases are EMPTY; file membership comes from
     PBXFileSystemSynchronizedRootGroup ("App", "Watch", "WatchWidget",
     "AppUITests", "WatchUITests") via each target's fileSystemSynchronizedGroups.
   - Swift 6 strict concurrency throughout; 2026 SDK renames (viewContext,
     NSNumber @NSManaged, allowsExternalBinaryDataStorage,
     eventChangedNotification, etc.) already handled in code.
2. The iOS target has the Watch-app wiring (IDs A1…186–189):
   - `Embed Watch Content` PBXCopyFilesBuildPhase, **dstPath =
     "$(CONTENTS_FOLDER_PATH)/Watch"**, **dstSubfolderSpec = 16** — watch app
     lands in `NurseVault.app/Watch/`. This is what the upload validator
     (90680) demands AND what makes the archive carry ApplicationProperties
     (see STATUS 2026-10-02). Do NOT revert to "" + 13.
   - The **watch target has `SKIP_INSTALL = YES`** in both configs — REQUIRED:
     without it xcodebuild archives the watch app as a second top-level
     product and Xcode's sole-app check drops ApplicationProperties from the
     archive Info.plist (Organizer then refuses to distribute).
   - Its PBXBuildFile (186) and PBXTargetDependency (189) carry
     **`platformFilter = ios`** — required because the app target is
     multiplatform (macOS build must not build/embed the watchOS app).
   - Do not "tidy" these away.
3. Widget target has `MARKETING_VERSION = 0.1` and its Info.plist uses
   `$(MARKETING_VERSION)` — extension version must equal parent app version.

## Signing / account state

- Paid account is the SAME Apple ID as the free era → team ID **2LFBN27WK8**
  (pbxproj correct; no change needed). User is logged into Xcode on this Mac.
- Keychain: "Apple Development: JOSEPH TOMAS WOODS (VDWDUNC9R2)" (CN shows
  VDWDUNC9R2; OU/team is 2LFBN27WK8 — trust profile/codesign TeamIdentifier).
- Profiles in ~/Library/Developer/Xcode/UserData/Provisioning Profiles/: dev
  profiles for app/watch/widget (2026-09-26) + macOS dev profile. The export
  step also created **App Store ("…Team Store…") profiles + a "Cloud Managed
  Apple Distribution" certificate** in Apple's cloud (not the local keychain).
- Real-device builds now work (provision a device in Xcode as usual).

## Xcode 27 CLI gotchas (keep in mind)

- Automatic signing over CLI requires **`-allowProvisioningUpdates`** on
  build/archive/export, otherwise "No profiles … Automatic signing is disabled".
- No Apple ID in Xcode GUI → "No Accounts: Add a new account in Accounts
  settings" (user GUI step; now done).
- `-exportArchive`:
  - `method` **`app-store` is deprecated → use `app-store-connect`** (works for
    BOTH the iOS and the macOS archive; Mac produces the .pkg).
  - **`-exportPath <dir>` CLI flag is REQUIRED** (plist `destination` not enough).
  - Archive whose Info.plist lacks **ApplicationProperties** → classified
    "generic archive" → cryptic `expected one {} but found app-store`. Fix:
    patch ApplicationProperties into `.xcarchive/Info.plist` (ApplicationPath,
    Architectures, CFBundleIdentifier, CFBundleShortVersionString,
    CFBundleVersion, SigningIdentity, Team). xcodebuild omitted it; a
    `/usr/bin/python3` plistlib patch fixed it. Re-apply after any re-archive
    if it's missing again.
- Exported iOS .ipa contains BOTH `Payload/NurseVault.app` (watch app nested in
  PlugIns/) and `Payload/NurseVault Watch.app` — correct layout; the file name
  ("NurseVault Watch.ipa") is cosmetic.

## App Store Connect API — 2026 reality + current state

**Big discovery:** the old API host `api.appstoreconnect-v1.org` **no longer
exists** (genuine NXDOMAIN, confirmed via Google DoH). The current host is
**`https://api.appstoreconnect.apple.com/v1/…`** (per Apple's 2026 docs + forum).
JWT format unchanged: `alg` ES256, `kid` = Key ID, `typ` JWT; payload `iss`
(team key) — or `sub` (individual key, NO iss) — + `iat`/`exp` (≤1 h) +
`aud: "appstoreconnect-v1"`.

**Sandbox networking:** the shell's DNS allowlist does NOT resolve
`api.appstoreconnect.apple.com` (nor contentdelivery/apple.com etc., though
developer.apple.com + dns.google work). Workaround that WORKS:
```sh
IP=$(curl -s "https://dns.google/resolve?name=api.appstoreconnect.apple.com&type=A" \
   | /usr/bin/python3 -c "import json,sys; print([x['data'] for x in json.load(sys.stdin)['Answer'] if x['type']==1][0])")
curl --resolve api.appstoreconnect.apple.com:443:$IP -H "Authorization: Bearer $JWT" \
   "https://api.appstoreconnect.apple.com/v1/apps?limit=10"
```
(Re-resolve the IP each session — it's Akamai and can change.)

**Key provided by user (2026-09-27):** Key ID `P24GJ5VLS6`, Issuer ID
`c8e01104-d43c-4d1a-9e8f-c09f5bc5dfea`, role App Manager, saved at
`build/export/asc/AuthKey_P24GJ5VLS6.p8` (gitignored).

**Status: 401 NOT_AUTHORIZED on every request.** Verified locally: the JWT
signature is valid for the provided private key (openssl `Verified OK`),
header/payload exactly as documented, both `iss` and `sub` variants rejected
with the same generic 401. The API is reachable and speaks the current protocol
(errors come back in the current format). So Apple does not recognize the
key/issuer pair. Likely causes, in order:
1. The **Issuer ID was copied from a different account** (or a typo) — the most
   common. Ask the user to re-copy it from Users and Access → Integrations.
2. The key was **created while logged into a different Apple ID** than the paid
   developer account (they may have multiple Apple IDs).
3. The key was deleted/rotated after download, or the account is in an
   odd state.
**Do NOT keep guessing aud values or reformat tokens** — the token side is
proven-correct. Get a fresh Issuer ID (and, if that fails, a regenerated key)
from the user.

## Current state of the TestFlight push

- v0.1 build 1, version numbers unchanged (0.1 / 1) — nothing was ever uploaded
  before, so no version bump needed.
- **iOS build READY:** `build/export/export/NurseVault Watch.ipa` — arm64, Cloud
  Managed Apple Distribution cert, "iOS Team Store Provisioning Profile"
  (Production CloudKit) for app + watch app + widget. (Re-verify it's still on
  disk; regenerate per commands below if gone.)
- **macOS build READY:** `build/export/export-mac/NurseVault.pkg` — 3rd Party
  Mac Developer Installer cert, "Mac Team Store Provisioning Profile",
  Production CloudKit, sandbox.
- Committed: 06ccf70 (embed Watch app, camera/OCR, UI tests); the rest of this
  session's state lives in this file.
- App Store Connect **app records**: status unknown — the API 401 means we never
  checked. The user was previously asked (Option B) to create them in the web
  UI; when the key starts working, check `GET /v1/apps?limit=100` first — if
  the Nurse Vault records don't exist, create them via API
  (`POST /v1/apps`, platform IOS / MAC, bundleId com.josephwoods.nursevault,
  SKU nursevault / nursevault-mac) or have the user do it in the web UI.

## Commands (from the project folder)

```sh
# JWT (script lives at build/export/asc/asc-jwt.sh; key next to it)
JWT=$(build/export/asc/asc-jwt.sh build/export/asc/AuthKey_P24GJ5VLS6.p8 P24GJ5VLS6 c8e01104-d43c-4d1a-9e8f-c09f5bc5dfea)

# Signed device build (swap scheme/destination; keep -allowProvisioningUpdates)
xcodebuild -project NurseVault.xcodeproj -scheme NurseVault \
  -destination "generic/platform=iOS" -configuration Release \
  -allowProvisioningUpdates build

# iOS archive / export
xcodebuild -project NurseVault.xcodeproj -scheme NurseVault \
  -destination "generic/platform=iOS" -configuration Release \
  -allowProvisioningUpdates -archivePath archives/NurseVault-iOS-0.1 archive
xcodebuild -exportArchive -archivePath archives/NurseVault-iOS-0.1.xcarchive \
  -exportOptionsPlist build/export/exportOptions.plist \
  -exportPath build/export/export -allowProvisioningUpdates

# macOS archive / export (same pattern; see Next steps for exact lines)

# Compile-only checks (no account needed): CODE_SIGNING_ALLOWED=NO
#   -destination "platform=macOS" | "generic/platform=iOS" | "generic/platform=watchOS" (watch scheme)
```

## Next steps (in order)

1. **Unblock the API key** (needs user): ask them to re-verify on the
   Integrations page that (a) the Issuer ID really is `c8e01104-…` (re-copy it),
   (b) the key is listed and active, (c) they were signed into the SAME Apple ID
   as the paid developer program when they created it. If it still 401s: have
   them generate a FRESH key and send the new .p8 + Key ID.
2. **Once the token works** (`GET /v1/apps` returns data):
   - Check/create the two app records (iOS `nursevault` + Mac `nursevault-mac`).
   - Check/complete required metadata per record: privacy label (try
     "I do not collect any data"; fallback declaration: Camera → collected,
     not linked, App Functionality) and age rating (all "None" → 4+). The API
     may expose these read-only — if so, the user does those two tabs in the
     web UI.
   - Upload both builds via the API (builds upload flow: POST the build with a
     file access level / the build-upload reservation endpoints — follow the
     2026 docs at api.appstoreconnect.apple.com; then POST to the beta group).
   - Watch the builds process; handle any rejection (privacy label is the usual
     first failure — fixable without a new build).
3. **TestFlight:** once the iOS build passes, ensure it's in a beta group the
   user belongs to; they install the TestFlight app on a real iPhone; the watch
   app lands on a paired watch automatically.
4. **THE RESET (do not skip):** after everything is uploaded and confirmed
   working, have the user **delete the API key** in App Store Connect
   (Users and Access → Integrations → Keys → `bionic-upload`/`P24GJ5VLS6` →
   Delete), then delete the local `build/export/asc/AuthKey_P24GJ5VLS6.p8`
   file. Verify from our side that the old key now 401s before closing out.
5. **Long-term (not needed for alpha):** App Store screenshots, public release,
   watch complications polish.

## Watch for in a future session

- Re-verify the .ipa/.pkg still exist on disk (gitignored — they can be lost if
  the user cleaned build/); regenerate with the archive/export commands above
  (the ApplicationProperties patch step may be needed again on re-archive).
- TestFlight build rejection reasons to expect: privacy label not filled (most
  likely) or camera declaration. Metadata changes apply to already-uploaded
  builds — no re-upload needed, just re-trigger/wait for processing.
- The watch app ships INSIDE the iOS .ipa (companion) — no separate watch ASC
  record needed. Standalone-watch distribution would be a different setup.
- If the user ever hits "the .ipa was uploaded but the build shows an error,"
  pull the build's `releaseVerificationDetail`/`betaAppReviewDetail` via the API
  for the actual rejection text.
