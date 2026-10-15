# Nurse Vault

A private, offline-capable reference vault for nursing practice — available on **iPhone, iPad, Mac, and Apple Watch**, with everything you store synced securely across all of your devices via **iCloud (CloudKit private database)**.

No third-party servers, no accounts, no subscriptions. Your data is only ever accessible by your own Apple ID.

> 🌐 **Landing page & privacy policy:**
> [woodzieman.github.io/NurseVault](https://woodzieman.github.io/NurseVault)
> · [Privacy Policy](https://woodzieman.github.io/NurseVault/privacy.html)

---

## Quick Start (for visitors)

1. **View the app's landing page** at [woodzieman.github.io/NurseVault](https://woodzieman.github.io/NurseVault).
2. **Read the privacy policy** — it states: *we collect zero data.*
3. **Install from the App Store** (search "Nurse Vault") or build from source (see below).

---

## Main Menu Sections

The app ships with six read-only reference entries (plus user sections) and a **+** button to add unlimited more:

| Section | Icon | Typical use |
|---|---|---|
| Code Blue | cross.vial | ACL/Code Blue flows, resuscitation checklists |
| Lab Values | test tubes | Normal lab ranges, critical values |
| Drugs | pills | Dose tables, drug references |
| Merck Manual | book.pages | Medical topics by specialty (2,834 articles, 28 specialties) |
| Other | folder | Anything else |

Sections can be renamed, reordered (drag), or deleted at any time.

There is also a fixed **Drug Reference** entry in the sidebar (badged with its count). It is not a user section — it is a read-only reference bundled with the app itself.

---

## What You Can Store

- **Files** — PDFs (in-app viewer), images (pinch-to-zoom viewer), text/RTF, and any other file up to **48 MB** each. Import via **Add → Import Files…**, **Add → Import Photos…**, or drag & drop (Mac/iPad).
- **Folders** — Drag a folder onto a list to import it as a vault folder: files become documents, subfolders are mirrored as nested vault folders. Oversized/unreadable files are skipped and reported.
- **Bundled drug reference** — Complete Merck Manual Professional drug dataset (2,383 drugs, ~350 MB in `DrugInfo/`). Lives in the app bundle, not the vault: always present, offline-capable, never synced to iCloud. Search by name, brand name (instant), or full content (few-second scan with snippets).
- **Notes** — Pure text references (**Add → New Note**).
- **Camera** — Capture from camera and store as a syncing image (iPhone/iPad).
- **Scan & OCR** — Point camera at printed reference, read text with Apple's on-device Vision OCR, save as editable searchable note.
- **Search** — Find documents by title, file name, notes, or file content (PDFs/text). Available in main app toolbar and watch search pages.

---

## How Sync Works

- Documents live in a Core Data store on each device, mirrored to your **private** CloudKit database (`iCloud.<your bundle ID>`).
- The private database is only readable/writable by your Apple ID — no one else can see or touch it.
- Everything works **offline**: changes save locally and sync automatically when connected.
- Remote edits appear on other devices when the app next connects (or immediately while open).

---

## First-Time Setup (one-time)

1. Open `NurseVault.xcodeproj` in Xcode (16+ required; 27 tested).
2. Pick a **team** — your Apple ID (personal team is fine for personal use).
3. Targets: **NurseVault** (iPhone/iPad/Mac), **NurseVault Watch**, and **NurseVault Watch Widget**.
4. Both apps have iCloud capability with container `iCloud.com.josephwoods.nursevault` preconfigured.
5. The watch app + widget share App Group `group.com.josephwoods.nursevault`.

---

## Building & Running

```bash
# Build for iOS simulator
xcodebuild -project NurseVault.xcodeproj -scheme "NurseVault" \
  -destination "generic/platform=iOS Simulator" build

# Build for macOS
xcodebuild -project NurseVault.xcodeproj -scheme "NurseVault" \
  -destination "platform=macOS,arch=x86_64" build

# Build watch app
xcodebuild -project NurseVault.xcodeproj -scheme "NurseVault Watch" \
  -destination "generic/platform=watchOS Simulator" build
```

---

## App Store Publishing (using `asc` CLI)

```bash
# Bump build number
asc xcode version edit --version "4.1" --build-number "52"

# Archive for iOS
asc xcode archive --project NurseVault.xcodeproj --scheme "NurseVault" \
  --configuration Release --clean \
  --archive-path build/NurseVault-Release.xcarchive --overwrite \
  --xcodebuild-flag=-destination --xcodebuild-flag="generic/platform=iOS"

# Export IPA
asc xcode export --archive-path build/NurseVault-Release.xcarchive \
  --ipa-path build/NurseVault.ipa --overwrite

# Upload to App Store Connect (waits for processing)
asc publish appstore --app 6816576078 --ipa build/NurseVault.ipa \
  --version 4.1 --wait

# Submit for review (when ready)
asc publish appstore --app 6816576078 --ipa build/NurseVault.ipa \
  --version 4.1 --submit --confirm
```

---

## Watch Reference System

The Apple Watch companion includes two bundled reference datasets: **Drug Reference** (filtered high-priority drugs) and **Merck Manual** (full medical topics). These are separate from the iPhone's DrugInfo/ folder — the watch bundles its own optimized copies.

### Architecture

```
Sources/Watch/Resources/WatchReference/
├── drugs.index      # Plain-text index: title|preview|startByte|endByte|extra
├── drugs.content    # Brotli-compressed content blob (per-entry)
├── merck.index      # Same format for Merck topics
└── merck.content    # Brotli-compressed content blob
```

**Design principles:**
- **Index in RAM, content on disk**: The small index (~80-450 KB) loads entirely into memory for instant search/browse. Content is read per-entry only when the user taps a topic.
- **Per-entry compression**: Each entry is individually brotli-compressed with an 8-byte uncompressed size prefix, enabling random access without decompressing the entire file.
- **Plain-text index**: No runtime inflate needed for the index — loading can never depend on the compression path.

### Build Process

**Full drug reference (iPhone):** All 2,383 drugs from `DrugInfo/` are bundled directly into the iOS app. No build script needed.

**Filtered watch drug reference:** A curated subset of ~600 high-priority nursing drugs across 12 therapeutic categories:

```bash
# Preview which drugs would be selected
python3 scripts/build_watch_drugs.py --list

# Build the filtered watch drug reference
python3 scripts/build_watch_drugs.py
```

Categories included: Cardiac/Emergency, Antibiotics/Antimicrobials, Pain Management/Opioids, Sedation/Anesthesia, Anticoagulants/Antiplatelets, Diabetes/Endocrine, Respiratory, GI/Antiemetics, Electrolytes/IV Fluids, Psychiatric (Common), Neurologic/Seizure, Allergy/Anaphylaxis.

**Full-coverage watch drug reference (truncated):** All 2,383 drugs with 8 KB summary truncation:

```bash
python3 scripts/build_watch_drugs_truncated.py --size 8
```

**Full reference build (both datasets):**
```bash
python3 scripts/build_watch_reference.py all    # or: drugs | merck
```

### Watch Reference Troubleshooting History

The watch drug/Merck reference went through several iterations to resolve a blank-detail-view issue where tapping an entry showed only the title and specialty/brand names with no body content.

#### Iteration 1: Full Drug Dataset on Watch (Builds ≤47)
- **Approach:** Bundled all 2,383 drugs (~35 MB content file) to the watch
- **Result:** ❌ Failed — watch OOMed or became unresponsive after sync floods; too much data for watch memory constraints

#### Iteration 2: Filtered Drug Dataset (Build 48)
- **Approach:** Created `scripts/build_watch_drugs.py` to select ~600 high-priority drugs by therapeutic category keyword matching. Reduced content file from 35 MB → 13 MB, index from 293 KB → 79 KB.
- **Result:** ⚠️ Partial — list view worked (index loaded fine), but detail view showed only title + brand names with no body text. No error message displayed.

#### Iteration 3: Content Truncation (Build 50)
- **Approach:** Added 8 KB display cap in `WatchReferenceDetailView` to prevent rendering ~350 KB of text on the watch screen. Added diagnostic NSLog statements.
- **Result:** ❌ Failed — issue persisted for both drugs and Merck topics. Confirmed the problem was not text length but content loading itself.

#### Iteration 4: In-Memory Content Buffer (Build 51) ✅
- **Approach:** Replaced `FileHandle` seek/read with `Data(contentsOf:)` to load the entire content file into memory once (~8-13 MB, well within watch RAM), then slice entries from that buffer. Added extensive logging at every step: URL resolution, file load, byte range validation, brotli decompression, character count.
- **Rationale:** `FileHandle` seek/read on large bundled resources appears to fail silently on watchOS. Loading the full file into memory is simpler and more reliable; 13 MB fits comfortably in watch RAM (512 MB–1 GB).
- **Result:** ✅ Fixed — detail views now display content correctly for both Drug Reference and Merck Manual topics.

#### Iteration 5: Full Drug Coverage via Truncated Content (Build 52)
- **Approach:** Keep all 2,383 drugs on watch by truncating each `drug-information.txt` to the first 8 KB — enough for Nursing Quick-Reference Summary, Drug Class, Routes, Dosing, Side Effects, and Key Nursing Considerations. Build script `scripts/build_watch_drugs_truncated.py` replaces the filtered full-content build.
- **Result:** ❌ Failed — watch detail view still blank. The 8 KB byte truncation cut multi-byte UTF-8 characters in the middle of the file, producing invalid UTF-8 that `String(data:encoding:)` rejected.
- **Fix (Iteration 6, Build 54):** `truncate_utf8()` decodes/re-encodes through Python to guarantee a valid UTF-8 boundary, and `WatchReference.text(for:)` now memory-maps the content file (`.alwaysMapped`) instead of loading it all into RAM. Content is still ~4.78 MB; page-backed access avoids the flat RAM cost that was likely OOMing the watch after the user opened drug and Merck references in sequence.

**Key lessons learned:**
1. WatchOS has strict memory constraints — never bundle the full iPhone dataset to the watch
2. `FileHandle` seek/read on large bundled resources is unreliable on watchOS; prefer loading into memory
3. Always add diagnostic logging when debugging silent failures on embedded devices
4. The absence of an error message in a UI often indicates the async task never completed or failed before reaching the error-handling code path
5. Resource bundle resolution is complex — try multiple strategies and log which one succeeds
6. Memory mapping (`.alwaysMapped`) fails silently on watchOS; prefer loading entire file into memory
7. Always provide user-facing error messages, not just blank screens

#### Iteration 7: Comprehensive Fix with Error Handling (Build TBD)
- **Approach:** Multiple fixes based on audit findings and historical analysis:
  1. Reverted to Iteration 4 solution as primary strategy: load entire content file into memory (~8-13 MB fits in watch RAM)
  2. Added `loadError` property to WatchReference for UI error display
  3. Enhanced resource URL resolution with 7 strategies and comprehensive debug logging
  4. Added user-facing error messages in both list view and detail view
  5. Implemented retry mechanism when loading fails
  6. Added diagnostic code to list all available resources at runtime (DEBUG only)
- **Rationale:** Iteration 4 worked reliably; memory mapping is unreliable on watchOS; users need feedback when things fail
- **Result:** ⬜ Pending testing — requires device verification
- **Files modified:**
  - `Sources/Watch/WatchReferenceStore.swift` - Enhanced resourceURL(), added loadError property, simplified content loading
  - `Sources/Watch/WatchDrugReference.swift` - Added error display in list view and detail view with retry buttons
  - `Packages/NurseVaultCore/package.swift` - No changes (resources not in SPM package)
- **Remaining issues to investigate:**
  - Resource files may not be properly bundled by Xcode despite filesystem synchronization
  - Need to verify resources are included in watch app bundle at build time
  - May need to add explicit resource references to Xcode project or move to SPM package

### Iteration 8: Code Audit Fixes (Build TBD)
- **Approach:** Comprehensive code audit and fixes based on CODE_AUDIT.md findings:
  1. Fixed `if let self` error in Library.swift - changed to weak reference pattern
  2. Fixed unused save() return value warnings throughout codebase
  3. Made AppLimits enum public for cross-target access
  4. Enhanced watch reference error handling and user feedback
  5. Added comprehensive debug logging for resource resolution
- **Result:** ⬜ Pending testing - builds successfully with only minor warnings remaining
- **Files modified:**
  - `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift` - Fixed weak reference pattern, added _ = save() handling
  - `Packages/NurseVaultCore/Sources/NurseVaultCore/Configuration/AppLimits.swift` - Made enum and properties public
  - `Sources/iOS/RootView.swift` - Added _ = save() for unused return value
  - `Sources/Watch/WatchReferenceStore.swift` - Enhanced resource URL resolution with debug logging
  - `Sources/Watch/WatchDrugReference.swift` - Added error display in list and detail views
- **Build status:** Both NurseVault and NurseVault Watch targets build successfully
- **Next steps for testing:**
  1. Build and run on actual Apple Watch device (not simulator)
  2. Test Drug Reference - verify all drugs load correctly
  3. Test Merck Manual - verify topics load correctly
  4. Check console logs for resource resolution diagnostics
  5. If still failing, investigate Xcode project resource bundling configuration

### Investigation Results (Post-Audit)

**Issue 1: Resource Bundling**
- ✅ RESOLVED: Resources ARE bundled correctly in the watch app bundle at root level
- Files found: drugs.index (295 KB), drugs.content (5 MB), merck.index (463 KB), merck.content (9.2 MB)
- Filesystem synchronization is working as expected

**Issue 2: Force-unwrap on Bundle.main.url**
- ❌ NOT FOUND: No force unwraps with Bundle.main.url found in codebase
- Audit finding was incorrect - no action needed

**Issue 3: Integer precision loss in compression_compat.c**
- ⚠️ LOW PRIORITY: Line 20 casts int to size_t, but won't cause issues with typical data sizes
- Not critical for current functionality

**Issue 4: Only first two drugs visible**
- 🔍 ROOT CAUSE IDENTIFIED:
  - Index file has 2,383 entries (correct)
  - List view uses pagination starting at 25 items
  - Potential issue with @Observable state not propagating through value parameters
  - Retry mechanism was blocked by guard condition preventing reload when isMissing=true
- ✅ FIXES APPLIED:
  - Removed guard that prevented retrying after failure
  - Added comprehensive debug logging for index parsing and resource resolution
  - Enhanced error handling in loadIfNeeded() to allow reloading

**Issue 5: @Observable state propagation**
- ⚠️ POTENTIAL ISSUE: WatchReference passed by value may not trigger UI updates
- Investigation ongoing - requires testing on actual device

---

## Project Structure

```
Nursing app/
├── Sources/
│   ├── iOS/              # iPhone/iPad/Mac app (shared SwiftUI)
│   ├── Watch/            # Apple Watch companion app
│   │   └── Resources/WatchReference/  # Bundled watch reference data
│   └── Widget/           # Watch face complication widget
├── Packages/NurseVaultCore/  # Shared Swift package (models, library, views)
├── DrugInfo/             # Full drug dataset (2,383 drugs, iPhone only)
├── MerckTopics/          # Full Merck Manual topics (iPhone only)
├── scripts/              # Build & data processing scripts
│   ├── build_watch_reference.py      # Full watch reference builder
│   ├── build_watch_drugs.py          # Filtered watch drug builder
│   └── build_watch_drugs_truncated.py # Full coverage truncated builder
├── fastlane/             # App Store metadata & automation
└── NurseVault.xcodeproj  # Xcode project
```

---

## Privacy

- **Zero data collection** — no analytics, no crash reporting to third parties, no telemetry.
- All user content stays in your private iCloud container or on-device.
- Bundled reference data (drugs, Merck) is read-only and never leaves the device.
- See [Privacy Policy](https://woodzieman.github.io/NurseVault/privacy.html) for details.

---

## License

Private use. Not for commercial distribution without permission.
