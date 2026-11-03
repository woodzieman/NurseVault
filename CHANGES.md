# Changes Summary — Nurse Vault (Nov 3, 2026)

## Book import: loading bar, real import, searchable text — v5.3 (build 84)

The book ingestion engine was non-functional: file-picked URLs are
security-scoped on iOS, and the old code started the scope in the
*synchronous* caller, then `defer` stopped it before the async extraction
ran — so every file read silently failed and no book was ever added.

1. **Fixed the import path** (`BooksView`, `ImportView`): the scope is now
   opened inside the engine's own reads and in `FileSupport.importFileAsync`
   (a new nonisolated wrapper so the blocking file read runs off the main
   actor). Imported books are saved with their text in `extractedText`
   (`Library.addDocument` gained the parameter) — the searchable-content
   field — and the search index now also indexes persisted `extractedText`
   for document kinds it classifies as `.other` (notably RTF books).
   Result: PDF/txt/RTF books are added *and* searchable from the universal
   search bar, including on the watch.
2. **Loading bar**: new shared `BookImportState` + `BookImportProgressOverlay`
   used by both Books and Import views; the engine reports ~100 progress
   ticks for PDFs (page-based) and coarse start/finish for text/RTF. Failed
   imports surface an error alert (scanned PDFs without a text layer get a
   specific message).
3. **Labs (tables tab) expanded**: Normal Lab Values now covers 15
   categories / ~70 tests, each with a plain-language description of what
   the test measures — electrolytes, renal, glucose/endocrine, hepatic,
   pancreatic, lipids, CBC, coagulation (+fibrinogen), cardiac, plus six new
   groups: blood gas (pH/PaCO2/PaO2/HCO3/base excess/SaO2/lactate),
   urinalysis, iron & bone (iron/TIBC/ferritin/vitamins/PTH), hormones
   (thyroid/cortisol/sex hormones/prolactin/hCG), tumor markers, and CSF.
   Ranges sourced from Medscape normal-adult values, NBME, and nursing
   references. The **watch** Lab Reference now renders all of it correctly
   (the earlier build showed nothing for lab values) in a vertical
   label/range/description layout, with all attribution sources listed.
4. **Code audit follow-through** (Nov 3 audit, committed in the previous
   build): all targets — iOS, watch, widget, macOS — build with 0 errors /
   0 warnings; also fixed a CZUR scan-state desync in ImportView (the view
   now observes the shared flow instance its progress UI depends on).
5. **DSM-5-TR dataset committed**: the 54 disorder text files that the
   index referenced but git never tracked (3.1 MB) are now in the repo,
   so a fresh clone builds the complete app.
6. Housekeeping: README (sidebar table, books) and the GitHub Pages site
   (What's New) updated for the release; fastlane metadata-validation
   ignore for the untracked helper folders.

---

## Universal Search UI fixes (from user screen recording, iOS 26)

Three layout/UX defects in the universal search flow, all fixed:

1. **Search field covered sidebar rows.** The system `.searchable` field,
   in the new iOS 26 design, floats in a Liquid Glass container at the
   *bottom* of the sidebar; list rows scrolled behind it and text showed
   through the glass. Replaced with `VaultSearchField` (new file
   `Sources/iOS/Search/VaultSearchField.swift`), a rounded field pinned
   above the sidebar list on iOS. macOS keeps the system `.searchable`.
2. **Back button overlapped the "Search Results" title.** On iOS 26 the
   floating glass back button spills below the navigation bar onto a large
   title. The results title is now inline (iOS only).
3. **Typing was cut off after two characters.** The results were shown by
   flipping the sidebar `selection` to `.searchResults`, which yanked the
   user off the search field. The collapsed split view now uses
   `preferredCompactColumn`: from 2 characters the detail column (results)
   is preferred without touching `selection`; the results screen carries its
   own copy of the search field (shared `localSearchText` binding) that
   re-focuses on appear, so the keyboard and field persist while results
   refine. Choosing a section or a result clears the query and restores the
   previous column behavior.

Also: `-debugSearch <text>` DEBUG launch argument for headless search
verification on the simulator; UI-test search helper now finds the plain
TextField on iOS. Verified on an iOS 27 simulator: sidebar, results, and
no-results states; iOS + macOS builds pass.

### Follow-up (same day): search results open the *specific* item

Selecting a result used to land on the category root (e.g. all 2,383 drugs)
instead of the chosen item. Now:

- `DrugReferenceView` / `MerckManualView` / `DsmManualView` take an
  `initialEntry` (+ `onEntryOpened`), convert their stacks to value-based
  navigation, and push the chosen entry on appear (filtering the list to it,
  so going back shows a short relevant list).
- Document results push a new `VaultDocRef` (persistent-ID URI) onto the
  vault stack owned by `RootView`; the destination resolves it via a new
  `Library.doc(withPersistentURI:)` fetch, with an in-memory-object fallback
  for OS versions whose SDK removed `NSPersistentIdentifier` (iOS 27 SDK
  note: URI→ID now goes through
  `NSPersistentStoreCoordinator.managedObjectID(for:)`, iOS 18+/macOS 15+).
- `-debugSelectResult <text>` DEBUG launch argument verifies the flow
  headlessly. Verified on the iOS 27 simulator: drug detail and DSM detail
  open directly from a search selection.

### Follow-up 2 (same day): calculators open the specific calculator

The same category-root problem applied to calculators: the deep-link handler
extracted the calculator ID and then threw it away, landing on all 174
items. The calculator stack is now value-based in RootView
(`calculatorPath` + `navigationDestination(for: CalculatorInfo.self)`),
search selection and `nursevault://calculator/<id>` deep links push the
specific calculator, and `CategoryListView` gained a name/category search
field that filters to the chosen calculator on appear. Verified on the iOS
27 simulator: selecting a BMI result opens the BMI calculator.

---

# Changes Summary — Nurse Vault (Oct 7, 2026)

## 1. GitHub Pages URLs (Marketing & Privacy)

**URLs:**
- Landing page: `https://woodzieman.github.io/NurseVault`
- Privacy policy: `https://woodzieman.github.io/NurseVault/privacy.html`

**Files changed:**
- `README.md` — Updated privacy policy link from local to external GitHub Pages URL
- `fastlane/metadata/en-us/marketing_url.txt` — `https://woodzieman.github.io/NurseVault`
- `fastlane/metadata/en-us/privacy_practice_url.txt` — `https://woodzieman.github.io/NurseVault/privacy.html`
- `fastlane/metadata/en-us/subtitle.txt` — "Offline Clinical Reference"
- `fastlane/metadata/en-us/promotional_text.txt` — "Private. Offline. No accounts."
- `fastlane/metadata/en-us/support_url.txt` — `https://woodzieman.github.io/NurseVault`
- `fastlane/metadata/en-us/description.txt` — App store description
- `fastlane/metadata/en-us/release_notes.txt` — Release notes

## 2. iPhone Image Zoom Fix

Added `ZoomableImageView` supporting:
- Pinch-to-zoom (1x to 4x) via MagnificationGesture
- Pan when zoomed in via DragGesture
- Double-tap to reset with spring animation

Changed `DocDetailView.swift` line 88: `VaultImageView` → `ZoomableImageView`

## 3. Apple Watch Fix — Sections, Documents & Navigation

The watch now reads document metadata from a summary file written by the main app,
instead of relying on its own empty Core Data store.

**New types (VaultModels.swift):**
- `WatchSection` — Identifiable: name, icon
- `WatchDoc` — Identifiable: title, fileName, mimeType, noteText, addedDateISO, sectionName, sectionIcon

**New summary (StoreLocation.swift):**
- `WatchVaultSummary` — JSON-serializable: sections array, documents array

**Library changes:**
- `watchSummary` — Loaded from App Group file on watchOS
- `writeWatchSummary()` — Writes structured metadata
- `watchSections` / `watchDocs` / `watchDocs(matching:)` / `watchDocs(in:)` — Computed properties returning Core Data data on iPhone/Mac, or summary data on watch

**Watch views (NurseVaultWatchApp.swift):**
- `WatchHomeView` — Uses `library.watchSections`
- `WatchDocListView` — Uses `WatchSection`, `library.watchDocs(in:)`, `library.watchDocs(matching:)`
- `WatchSearchView` — Uses `library.watchDocs(matching:)`
- `WatchDocDetailView` — Now takes `WatchDoc`, displays notes and metadata

## 4. Watch Zoomable Image (package-level)

`WatchZoomableImageView` moved to `VaultViews.swift` (public, `#if os(watchOS)` block).

---

## Build Status
- ✅ `NurseVaultCore` package — builds clean
- ✅ `NurseVault` iOS — builds clean (iPhone 18 Pro simulator)
- ⏭️ `NurseVault Watch` — watch simulator not available (core package compiles for watchOS)

---

# Changes Summary — Nurse Vault v4.4 (Oct 27, 2026)

## Cranial Nerve Search Fix

**Issue:** Searching for "cranial" or "cranial nerves" in the Merck Manual reference returned no results, even though the cranial nerve assessment topic was included in the index.

**Root Cause:** The empty state overlay in `MerckTopicViews.swift` showed "No Results" when content hits were empty, but didn't account for name/title matches found by `nameHits(for:)`. When searching for terms that matched topic names but not file contents, valid results were hidden behind the "No Results" overlay.

**Fix:** Changed the empty state condition from checking only `contentHits.isEmpty` to checking `visibleHits.isEmpty`, which includes both content and name/title matches. Now searches correctly show all matching topics regardless of whether they match by name or content.

**Files changed:**
- `Sources/iOS/MerckManual/MerckTopicViews.swift` — Fixed empty state condition in search results view

## App Store Upload (v4.4, build 68)

Uploaded to App Store Connect using the `asc` CLI:
- Version: 4.4
- Build number: 68
- Archive path: `.asc/artifacts/NurseVault-4.4.xcarchive`
- IPA path: `.asc/artifacts/NurseVault-4.4.ipa`
- App ID: 6816576078

**Upload workflow documented in README.md:**
```bash
# Bump version
asc xcode version edit --version "4.4" --build-number "68"

# Archive and export
asc xcode archive --project "NurseVault.xcodeproj" --scheme "NurseVault" \
  --configuration Release --clean --archive-path ".asc/artifacts/NurseVault-4.4.xcarchive" --overwrite
asc xcode export --archive-path ".asc/artifacts/NurseVault-4.4.xcarchive" \
  --ipa-path ".asc/artifacts/NurseVault-4.4.ipa" --overwrite

# Upload to App Store Connect
asc publish appstore --app 6816576078 --ipa ".asc/artifacts/NurseVault-4.4.ipa" --version 4.4 --wait
```

**Note:** The `asc publish appstore` command may report an error about "cannot create a new version" even after successful upload. Verify by checking the builds list: `asc builds list --app 6816576078 --platform IOS --output table`

---

# Changes Summary — Nurse Vault (Oct 28, 2026)

## 1. Watch Drug/Merck/DSM Detail: White Box + "(N/M)" Split — Fixed (Bug #1)

User-reported: watch Drug Reference detail showed an omnipresent white panel
blocking most content, plus a "(1/2)" split with a Prev/Next footer.

**Root cause:** an uncommitted intermediate revision of
`WatchReferenceDetailView` (Sources/Watch/WatchDrugReference.swift) paged the
entry at an 8 KB cap and painted a large `Color.white.opacity(0.9)` panel over
the scroll content (white body text on it → unreadable).

**Fix (clean removal, no page hack):**
- Deleted the dead pagination machinery (`pageIndex`/`pageSize`/`totalPages`/
  `pageRange`/`pageText`/`paginatedTitle` + ZStack + sticky footer).
- The entry now renders as one long `Text` in a `ScrollView` — no cap, no
  footer, adapts to light/dark automatically. "View continued" link, error and
  loading states retained.
- The shared `bodyText(for:)` header strip now also skips DSM header lines
  (`ICD-10-CM:`, `DSM-5-TR CONTENT:`); drug/Merck files never carry those.

**Verified on Apple Watch Series 12 simulator (watchOS 27):** new DEBUG
deep-jump hook (`-debugDetail <dataset> [title]`) + `simctl io screenshot`:
`guanFACINE` (drugs), a Merck diabetes topic, and a DSM entry all render
readable white-on-dark with no panel and no "(N/M)".

## 2. DSM-5-TR Reference: Data Fixes

- `DSM5TR/Condition.txt` was a bad extraction (source name wrapped across two
  lines): misnamed "Condition" and over-extracted through the rest of the
  anxiety chapter (133 KB). Renamed to
  `Anxiety_Disorder_Due_to_Another_Medical_Condition.txt`, truncated at the
  next-disorder boundary (matching every other file's convention), title +
  index entry updated (F06.4). All 54 index entries re-verified to resolve in
  the built iOS bundle.
- The "3 malformed ICD codes" (F15.920/F16.983/F17.203) from the earlier
  audit were a false positive — they are valid ICD-10-CM codes. No change.
- `DSM5TR_full/` (201 empty `[Criteria extracted from …]` stub templates) is
  **not** bundled anywhere; left on disk pending user decision (recommend
  delete).
- iOS DSM detail view now strips its metadata header (===/ICD/CONTENT label)
  via the cached body string, matching the Merck detail; previously it
  rendered the raw header lines.
- F41.8 Other Specified / F41.9 Unspecified Anxiety Disorder content existed
  only inside the Condition.txt bleed and is now gone from the dataset —
  proposed as 2 new entries (needs user go-ahead).

## 3. DSM-5-TR on the Watch (parity with Merck)

- `WatchReference.Name.dsm` + `WatchDsmReferenceView` ("DSM-5-TR" tab on the
  watch home; search placeholder "Disorder, symptom, or ICD code").
- `scripts/build_watch_reference.py` gained a `dsm` collector (titles/codes
  from `dsm5tr_index.json`; row `extra` = ICD code) → generates
  `Sources/Watch/Resources/WatchReference/dsm.index` (7 KB plain) +
  `dsm.content` (0.7 MB per-entry brotli, 54 entries) — auto-picked-up by the
  filesystem-synchronized Watch group. Round-trip verified by the script.
- Verified on watch sim: tab listed, 54 entries, detail shows ICD caption +
  clean body.

## 4. DSM-5-TR in Universal Search (iOS)

- `SearchResult.dsmTopic` case + row rendering (cross.case icon, "DSM-5-TR"
  category); `UniversalSearchManager` searches the DSM library alongside
  drugs/Merck/calculators/vault; selecting a hit opens the DSM-5-TR tab.
- `RootView` passes `dsmLibrary` into the manager + re-searches when the DSM
  library finishes loading (mirrors the Merck pattern).

## 5. Watch App: DEBUG Deep-Jump (testability)

- `NurseVaultWatchApp` `WatchHomeView` honors launch argument
  `-debugDetail <drugs|merck|dsm> [title]` (DEBUG builds) and opens that
  entry's detail directly — enables headless `simctl` screenshot verification
  (the watch simulator has no public UI-scripting API). Inert in Release.

## Build Status (Oct 28, 2026)

- `NurseVault` (iOS, iPhone 17 sim): **BUILD SUCCEEDED**
- `NurseVault Watch` (watchOS 27, Series 12 46mm sim): **BUILD SUCCEEDED**
  + installed/launched; drug, Merck, and DSM details verified by screenshot.

## 6. iPhone/iPad Layout: 2-Column Split + Safari-Style Menu Toggle (Bug #2)

User-reported: landscape iPhone showed a very narrow reference column plus a huge
empty third column (a stray "Select a Document" warning triangle) — poor use of
screen real estate; asked for a Safari-style way to hide the left menu.

**Root cause:** `RootView` used a 3-column `NavigationSplitView`, but every
reference/vault view owns its own `NavigationStack` inside the *content* column —
the *detail* column was a dead placeholder.

**Fix (Sources/iOS/RootView.swift):**
- Collapsed to **2 columns** (sidebar + detail): references and vault documents
  now fill the entire detail column (~70% of landscape width vs ~26% before);
  the dead placeholder column is gone.
- **Safari-style sidebar toggle**: `sidebar.leading` toolbar button (iOS) and
  ⌘0 (macOS) collapse/restore the menu column via `NavigationSplitViewVisibility`
  — hidden menu gives the reference 100% width.
- Sidebar width bounded on iOS (220–320 pt) so the content column stays dominant.
- DEBUG launch args for headless verification: `-debugSelect
  <all|drugs|calculators|merck|dsm|labs>` and `-hideSidebar` (inert in Release).

**Verified on simulators:** iPad 13" two-column layout, iPad with menu hidden
(full-width Merck Manual), iPhone 17 portrait single-column.

**Also (unblocks the macOS slice):** the multiplatform `NurseVault` target had
pre-existing macOS build breaks (committed code): unguarded
`navigationBarTitleDisplayMode` (LabsView ×3, CalculatorDetailView, ObstetricsView,
CategoryListView, EBMStatisticsView) and unguarded `.keyboardType(.decimalPad)`
(×11 across MedCalcEngine/EBMStatisticsView/OtherView). Added `#if os(iOS)`
guards + new `Sources/iOS/PlatformKeyboard.swift` with a `decimalPadKeyboard()`
cross-platform helper (no-op on macOS). macOS **BUILD SUCCEEDED** (was failing).

## 7. App Store Upload — v4.11, build 71 (Oct 29, 2026)

Shipped the Oct 28 work as a new App Store build.

- **Fixed a version-edit slip before archiving:** the earlier `asc xcode version
  edit --next-build-number` run had written `CURRENT_PROJECT_VERSION = 1` into the
  Release config (stale local max, not the remote-safe 71). Corrected to 71 and
  synced the stale Debug config to 4.11/71 as well. Watch + Watch Widget targets
  intentionally stay at 4.3/66 (inherited from project settings — the v4.10
  archive shipped the same values and App Store accepted it).
- Archive `NurseVault-4.11.xcarchive` (clean Release, `generic/platform=iOS`)
  → automatic-signing export → `NurseVault-4.11.ipa` (94 MB).
  Archive contents verified: app 4.11/71, embedded watch 4.3/66, `DSM5TR/`
  (54 files + index) in the app bundle, `dsm.index`/`dsm.content` in the watch app.
- **Uploaded to App Store Connect: build 71 `VALID`** (build ID
  `9b46d419-7d1e-4ce3-baac-0987418ad015`, App Store-eligible, TestFlight-ready,
  expires Jan 27, 2027).

**Not done (needs explicit go-ahead):** TestFlight distribution,
App Store review submission, version metadata updates.
