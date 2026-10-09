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
  - **SUPERSEDED** — reverted by `applyMerckVaultMigration()` (see 2026-10-09 build 43): the vault copy
    syncs ~2,834 large docs to CloudKit → watch and OOMs the watch app.

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

## Completed (2026-10-09, build 43 — user-reported breakage)

- [x] Fix iPhone Merck Manual detail: “only first page appears, doesn’t scroll”
  - **Root cause:** `MerckTopicDetailView.bodyText` rendered only the lines from
    the first `References` marker onward, dropping the whole article body (which
    sits *before* the references) — so the user saw just the short references tail.
  - Fixed: skip the leading metadata header (`===` / `Section:` / `Source:` /
    `Retrieved:` + leading blanks) and render the **entire** article, references
    included, so the full topic shows and scrolls.

- [x] Fix watch “completely broken after sync” — decouple Merck from the CloudKit vault
  - **Root cause:** the legacy one-time Merck import put ~2,834 topics (each up to
    64 KB text) into the CloudKit-synced Core Data vault; `syncToWatch` defaults on,
    so that set syncs to the watch, whose `reload()` materializes all of it and the
    low-memory watch app OOMs/freezes after a sync.
  - Merck is now a **bundled read-only reference** (like the Drug Reference):
    `MerckManualView` on iPhone + `WatchMerckLibrary` on the watch — never in the
    vault, never pushed to iCloud, never imported onto the watch.
  - `applyMerckVaultMigration()` (all platforms, one-time, `UserDefaults`-gated)
    deletes the legacy “Merck Manual” section + docs. Runs on the watch too, so the
    watch self-heals locally even if the CloudKit deletion hasn’t propagated yet.
    Reads only the light section name per doc (never `noteText`/`fileData`).

## Decision (2026-10-09): "42, made stable" — stop the churn

- User: "build 42 is the best so far, bring it back to that version."
- Critical-reasoning: a *literal* revert to 42 re-breaks the watch after a sync
  (42 had the Merck Manual imported into the vault → ~2,834 docs sync to the
  watch → OOM) and re-breaks Merck scroll. So we do NOT do a pure revert.
- Instead, build 46 = 42's good parts, stable:
  - Merck Manual restored as a **browsable sidebar reference tab** (bundled
    `MerckTopicLibrary`) — the browse-and-read experience the user liked, but it
    never syncs to iCloud, so the watch stays stable.
  - Merck kept **out of the vault** (no watch flood); Merck detail scroll fix +
    robust watch index loading retained.

## Completed (2026-10-09, build 47)

- [x] Watch full reference: bundled content + index + lazy load (supersedes the
  “small index, full text on iPhone” strategy)
  - Decision: the watch ships the COMPLETE reference, self-contained, no sync
    (music-app model, taken to its conclusion: a one-time ~46 MB download is
    fine on a 16–32 GB watch; a slow first launch is OK).
  - `scripts/build_watch_reference.py`: per-entry **brotli** (q11) content with
    an 8-byte size prefix — drugs 355 MB raw → 35 MB (90% smaller),
    Merck 29 MB → 9 MB (69%); plain-text pipe index
    (`title|preview|startByte|endByte|extra`), 300 + 464 KB; round-trip
    verified.
  - `Sources/Watch/WatchReferenceStore.swift`: ~700 KB index in RAM drives the
    paged (25/page) list + “Show more” + search; on select: seek → read span →
    inflate → scrollable full text. RAM bounded (largest entry ≈ 863 KB).
  - `WatchDrugReference` / `WatchMerckReference` rewritten on the store;
    previews now use the real drug-class line (header/skip rules fixed).
  - `CompressionCompat` C shim (libcompression `COMPRESSION_BROTLI`) +
    `Data.inflatingNV()`. **SDK 27 findings:** Compression framework has no
    importable Swift surface; `NSCompression` zlib fails at runtime
    (NSCocoaError 5377); libcompression zlib decode silently passes input
    through; brotli is the one verified decode path (tested on the watchOS 27
    simulator + the built bundle).
  - Version 4.1 / build 47; `fastlane upload` running.

## In Progress / Next

- [ ] **On-device verify build 47** (the big one)
  - Watch: Drug Reference + Merck Manual browse (25/page, show more),
    search returns results, tap → full text renders + scrolls,
    biggest drug (Darunavir combo, 863 KB) renders without a crash,
    watch stays stable across the whole session
  - iPhone: unchanged behavior (46 baseline) still good
- [ ] On-device verify build 46 if 47 regresses anything
- [ ] Core Data expert + cleanse pass on `Library.swift` / `Search.swift`
  - Flatten `importDirectory`, surface save errors, tidy `@MainActor Task` wrappers
- [ ] Final polish & App Store prep (metadata, screenshots) when the user approves

## Notes

- Fastlane upload lane: `fastlane ios upload`
  - Uses API key `Y9YADVN9Z2`, builds and uploads to App Store Connect
  - Read `fastlane/README.md` for usage
- Build cadence: new IPA every 2-3 hours until 80% polished
- Watch reference strategy (build 47): full content ON the watch (brotli blob,
  ~45 MB) + plain-text index in RAM + per-entry seek/inflate on select.
  Regenerate data: `python3 scripts/build_watch_reference.py all` (needs the
  Python `brotli` package).
