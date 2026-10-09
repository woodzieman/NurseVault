# Nurse Vault TODO / Progress

## Completed (2026-10-08 to 2026-10-09)

- [x] Strip “NURSING QUICK-REFERENCE SUMMARY” header from watch drug summaries
  - Updated `scripts/build_drug_guide_watch.py` to drop auto-generated boilerplate and keep real nursing info
  - Regenerated `WatchDrugIndex.json` → 0.68 MB (down from ~3 MB)
  - Copied to `Packages/NurseVaultCore/Resources/WatchDrugIndex.json` and `.../Sources/.../Resources/WatchDrugIndex.json`

- [x] Add watch Merck Manual index
  - Generated `scripts/merck_watch_index.json` (2.75 MB, 2,834 entries)
  - Added `WatchMerckLibrary.swift` mirroring `WatchDrugLibrary`
  - Added `WatchMerckReferenceView` and `WatchMerckDetailView` to watch UI
  - Updated `WatchHomeView` with “Merck Manual” entry
  - Updated `Package.swift` to bundle `WatchMerckIndex.json`

- [x] Build and export
  - Archived `NurseVault.xcodeproj` → `/tmp/NurseVault.xcarchive`
  - Exported IPA → `NurseVault_build_20261008.ipa` in workspace
  - Build succeeds clean for iOS/watchOS

- [x] Fix watch build failure 2026-10-08 23:05
  - Root cause: `Data.decompressed(using:)` unavailable in Swift 6.4 / SDK 27 toolchain for watchOS target
  - Fixed by bridging to `NSData.decompressed(using:)` in `WatchMerckLibrary.build()`
  - Build now succeeds for iOS + watchOS

- [x] Watch index compression & pipe format
  - Drug index: pipe-delimited `WatchDrugIndex.txt` 491 KB (was 693 KB JSON)
  - Merck index: zlib-compressed pipe-delimited `WatchMerckIndex.txt.zlib` 606 KB (was 2.7 MB JSON)
  - Both indices searchable on watch, header stripping confirmed

- [x] One-time Merck Manual migration into vault
  - `Library.ensureMerckManualImported()` implemented, creates “Merck Manual” section and imports topics from bundle as `VaultDoc` notes
  - 64 KB cap per doc, background import, skips if already imported

## Completed (2026-10-09, v4.1 breakage)

- [x] Fix iPhone Drug Reference "tapping shows no info" (build 4.1 regression)
  - **Root cause:** `text.split(whereSeparator: \.isNewline)` defaults to
    `omittingEmptySubsequences: true`, which collapsed the blank-line
    delimiters — the summary state machine never reached the pairs state, so
    **every** drug's Quick Reference Summary parsed empty, and the TOC
    produced 13 duplicate empty sections.
  - Fixed in `DrugReference.parse`: split with `omittingEmptySubsequences: false`,
    walk all summary pairs (stop only at the first non-pair line), and parse
    detailed sections by mapping every header (singular + plural) to one
    canonical title and appending (TOC entries + real sections merge; the
    Elsevier disclaimer is stripped).
  - `DrugInfoParsed.summary` is now an ordered `[(key, value)]` so it reads
    top-down instead of alphabetical.
  - Validated across **all 2,383** drug files: 0 with an empty summary, 0 with
    an empty section. Combo + Merck-native formats both parse.

- [x] Fix watch "shows 100 names per drug"
  - Rewrote `scripts/build_drug_guide_watch.py` → clean pipe format
    `<generic>|<brand1>|<brand2>|<summary>` (was a malformed variable field
    count). Max 2 brand names, `|` is safe (no brand/generic/summary contains
    a pipe). Regenerated `WatchDrugIndex.txt` → 2,383 drugs, **415 KB**.
  - `WatchDrugLibrary` now splits on 4 fields; row + detail show generic + up
    to two brands + the drug-class line.

- [x] Combo (hyphenated) drugs on the watch — **kept whole**
  - 484 combos. Each has its *own* brand names (e.g. Excedrin) and *own*
    combination dosing that differ from the components; 92 combos have no
    separate entry for a component at all. Search "Excedrin" resolves *only*
    to the combo entries, so splitting into components would lose data.
  - Decision: include all combos as their own watch entries (no splitting).
    An explicit exceptions list can be added later if a combo ever proves
    redundant — none do as of this dataset.

- [x] Shrink the watch Merck index
  - Rewrote `scripts/build_merck_watch_index.py` → zlib-compressed pipe text
    (first-paragraph summary). `WatchMerckIndex.txt.zlib` is now **96 KB**
    (was 606 KB). Removed the stale duplicate `Resources` folder + `.json`.

## In Progress / Next

- [ ] Verify search + sync + 3 GB PDF on the on-device test device
  - Drug reference detail now populates (Class/Routes/Side Effects/Overdose/
    Nursing + real sections); confirm on the phone
  - Search (name/brand/content) and the sync badge state
  - Confirm the size guards prevent the 3 GB PDF crash / OOM
- [ ] Core Data expert + cleanse pass on `Library.swift` / `Search.swift`
  - Flatten `importDirectory`, surface save errors, tidy `@MainActor Task` wrappers
- [ ] Final polish & App Store prep
  - Run cleanse pass, kick off archive/export, deliver IPA for on-device test
  - Proceed with fastlane upload when the user approves

## Notes

- Fastlane upload lane: `fastlane ios upload`
  - Uses API key `Y9YADVN9Z2`, builds and uploads to App Store Connect
  - Read `fastlane/README.md` for usage
- Build cadence: new IPA every 2-3 hours until 80% polished
- Watch storage strategy: small compressed indices for search, full content stays on iPhone/Mac
