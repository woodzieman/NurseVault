# DSM-5-TR + Bug Fix Plan (persistent — keep updated as phases complete)

Session goal (user):
1. **Bug #1** — watch Drug Reference detail is unreadable: white area covers most of the
   entry ("the white is omnipresent on the entry, not just the bottom") + "(1/2)" split.
2. **DSM-5-TR data** — newly added data must be entered correctly, no bugs, and be
   searchable **like the Merck data** (iOS + watch + universal search).
3. Finish all remaining TODO items.
4. Verify on virtual devices (Xcode/simctl) where possible.

Source of truth for DSM content: https://archive.org/stream/dsm-5-tr_202412/DSM-5-TR_djvu.txt
(local copy: /tmp/DSM-5-TR_djvu.txt, 3.69 MB — re-download if gone).

---

## Phase A — Bug #1: watch reference detail white-out (ACTIVE)

### Root cause (confirmed from user screenshots)
The user's installed build (uncommitted intermediate work, post-15846f6) had in
`WatchReferenceDetailView` (Sources/Watch/WatchDrugReference.swift):
- an **8 KB page cap** → "(N/M)" title + Prev/Next footer ("split entry"), and
- a **large `Color.white.opacity(0.9)` background** covering ~half the screen, with
  white (dark-mode) body text underneath → "can't read what is under the white".
The current working tree already has a pragmatic patch (pageSize = 50_000_000 →
totalPages = 1, footer `.thinMaterial`), so the footer can no longer appear — but the
dead pagination machinery is still there and unverified on device.

### Tasks
- [x] **A1** Clean `WatchReferenceDetailView`: delete dead pagination (`pageIndex`,
      `pageSize`, `totalPages`, `pageRange`, `pageText`, `paginatedTitle`, ZStack +
      footer) and render the full `Text(bodyText)` in a single `ScrollView`
      (mirrors committed 15846f6 behavior minus the 8 KB truncation, and matches
      the Merck iOS detail). Keep: `entry.extra` caption, error/loading states,
      "View continued" link, `.task(id:)` load logic.
- [x] **A2** Add `"ICD-10-CM:"` + `"DSM-5-TR CONTENT:"` to `bodyText(for:)` header
      prefixes in the SAME shared function — safe for drugs/Merck (those files never
      carry those prefixes); only DSM entries gain the strip (redundant with row `extra`
      and generator label).
- [x] **A3** Add a DEBUG-only launch-arg jump to the watch app root
      (`-debugDetail <dataset> <title>` → navigates straight to that entry's detail)
      so the detail can be screenshotted headlessly via
      `xcrun simctl io <device> screenshot` (no UI scripting available).
- [x] **A4** Build `NurseVault Watch` → install on Apple Watch Series 12 46mm
      (E7B2472A-9FEC-4B81-8F5D-965474CF678E) → launch with jump arg for `drugs` +
      `guanFACINE` → screenshot → verify: no white panel, no (N/M), readable text.
- [x] **A5** Re-verify a Merck watch entry detail the same way (shared view change
      must not break Merck).

## Phase B — DSM data correctness (fix what was entered)

Audit findings (this session, host python3):
- Index `DSM5TR/dsm5tr_index.json`: v1.0, 54 entries, **all** `relative_path` resolve,
  no duplicate ids/paths, every on-disk `.txt` is indexed, all decode UTF-8.
  Index keys: id, title, code, relative_path, searchName (no specialty/sub/section —
  the iOS library defaults those to "" and the views handle that).
- **`Condition.txt` is a bad extraction (real bug):** title "Condition" — the source
  name "Anxiety Disorder Due to Another Medical / Condition" (F06.4) wrapped across
  two lines and the extractor lost it. File runs 2,942 lines / 133 KB: it starts at
  source line 27051 (`Diagnostic Criteria F06.4`) and bleeds through the rest of the
  anxiety chapter to the "Reactive Attachment Disorder" heading. It **is** in the index
  (id `condition`) — earlier handoff called it an orphan; that was wrong.
- ICD codes `F15.920` / `F16.983` / `F17.203` are **valid** ICD-10-CM codes
  (3-digit extensions are standard) — earlier "malformed" flag was a regex false
  positive. No change.
- OCR artifacts (`_`, `§`, `FO6`, `Zag`) exist in the archive.org source too → keep
  as-is (source-faithful), per earlier decision.
- `DSM5TR_full/` = 201 files, **all** contain the `[Criteria extracted from DSM-5-TR
  Section II]` stub marker = empty templates, zero real content. Not in the index,
  not referenced in pbxproj (not bundled). Untracked in git.

### Tasks
- [x] **B1** Fix the F06.4 entry: truncate `Condition.txt` content at the
      "Other Specified Anxiety Disorder" heading (inclusive — matches the extractor
      convention seen in every other file, e.g. Bulimia ends at "Binge-Eating
      Disorder"), rename file to `Anxiety_Disorder_Due_to_Another_Medical_Condition.txt`,
      fix the `===` title line, update index entry (id/title/relative_path/searchName;
      code stays F06.4).
- [x] **B2** Remove the now-stale `Condition.txt` exclusion in
      `DsmTopicLibrary.directoryScan`.
- [x] **B3** `DSM5TR_full/`: confirm never bundled (pbxproj check — done: absent) →
      leave on disk, flag to user as "recommend delete" (201 empty stubs).
- [x] **B4** Flag (user decision): F41.8 Other Specified Anxiety Disorder + F41.9
      Unspecified Anxiety Disorder content existed ONLY inside the Condition.txt bleed;
      after B1 it's gone from the dataset. Propose extracting them as 2 new entries.

## Phase C — DSM watch parity (searchable like Merck, on watch)

- [x] **C1** `WatchReference.Name`: add `case dsm` (rawValue "dsm", label "DSM-5-TR").
      (No `allCases`/exhaustive-switch usages found — safe.)
- [x] **C2** Extend `scripts/build_watch_reference.py` with a `dsm` collector:
      read `DSM5TR/*.txt` (skip the index json), titles/codes from `dsm5tr_index.json`,
      `extra` = ICD code, preview via `make_preview` (add `ICD-10-CM:` /
      `DSM-5-TR CONTENT:` to `HEADER_PREFIXES` — safe, no drug/merck file starts
      with them).
- [x] **C3** Run `python3 scripts/build_watch_reference.py dsm` → generates
      `Sources/Watch/Resources/WatchReference/dsm.index` + `dsm.content`
      (auto-picked-up by the filesystem-synchronized `Sources/Watch` group; script
      round-trip-verifies the brotli blob).
- [x] **C4** Watch UI: `WatchHomeDestination.dsmReference` + NavigationLink
      ("DSM-5-TR") in `WatchHomeView` + `WatchDsmReferenceView` mirroring
      `WatchDrugReferenceView` (`WatchReference(.dsm)`, placeholder "Disorder or ICD
      code").
- [x] **C5** Verify on watch sim: home shows the tab, list loads 54 entries, one
      entry detail renders (screenshot).

## Phase D — DSM in iOS universal search

- [x] **D1** `SearchResult`: add `case dsmTopic(DsmTopicEntry)` (+ id
      `"dsm-\(entry.id)"`).
- [x] **D2** `UniversalSearchManager`: init takes `dsmLibrary`; `isLoadingLibraries`
      includes it; `performSearch` adds `dsmLibrary.nameHits`.
- [x] **D3** `SearchResultRow` (UniversalSearchResultsView): `.dsmTopic` cases in
      icon/title/category (icon `cross.case`, category "DSM-5-TR").
- [x] **D4** `RootView.handleSearchResultSelection`: `.dsmTopic` →
      `selection = .dsmManual`.
- [x] **D5** `RootView`: pass `dsmLibrary` into the manager init + add a
      `dsmLibrary.isLoading` re-search `onChange` (mirror the Merck one).

## Phase E — Build, verify, document

- [x] **E1** `xcodebuild` NurseVault (iOS): expect BUILD SUCCEEDED.
- [x] **E2** `xcodebuild` NurseVault Watch: expect BUILD SUCCEEDED.
- [x] **E3** Watch-sim verification: Phase A4 + A5 + C5 screenshots.
- [x] **E4** Optional: iOS iPhone-sim launch + screenshot (sidebar shows DSM-5-TR).
- [x] **E5** Update this doc's statuses; append a CHANGES.md entry.
- [x] **E6** Final user summary + open questions:
      - [x] ship: **DONE Oct 29** — v4.11 build 71 uploaded to App Store
        Connect, **VALID** (build ID 9b46d419-7d1e-4ce3-baac-0987418ad015).
        TestFlight distribution + review submission NOT done (needs go-ahead).
      - [ ] delete `DSM5TR_full/` (201 empty stubs)? — still open, user decision
      - [ ] add F41.8/F41.9 entries? — still open, user decision

---

## Phase F — Bug #2: landscape screen use + Safari-style menu hide (user-reported Oct 28)

User screenshot: landscape iPhone showing sidebar + very narrow Merck content
column (text wrapping every 2–3 words) + huge **empty** right column with a stray
warning triangle. Ask: "poor use of screen real estate… hide the menu like Safari."

**Root cause:** `RootView` was a **3-column** `NavigationSplitView`; every
reference/vault view owns its own `NavigationStack` in the *content* column, so
the *detail* column was a dead "Select a Document" `ContentUnavailableView`
(the warning triangle) eating ~50% of landscape width.

### Tasks
- [x] **F1** Collapsed to **2 columns** (sidebar + detail): merged `content:` into
      `detail:`, removed the dead placeholder. References/vault fill the detail
      column (~70% landscape width vs ~26% before).
- [x] **F2** Safari-style sidebar toggle: `NavigationSplitViewVisibility` state +
      `sidebar.leading` toolbar button (iOS) / ⌘0 (macOS); sidebar width bounded
      on iOS (220–320 pt); removed the stale 2nd macOS column-width modifier.
- [x] **F3** DEBUG launch args: `-debugSelect <all|drugs|calculators|merck|dsm|labs>`
      + `-hideSidebar` (delayed binding assignment — sync onAppear gets overridden
      by the system default).
- [x] **F4** Build iOS ✓; verified on sims: iPad 13″ 2-col, iPad no-sidebar
      (100% width, toggle top-left), iPhone 17 portrait single column.
- [x] **F5** macOS build: the multiplatform target had **pre-existing**
      macOS breaks (unguarded `navigationBarTitleDisplayMode` in Labs/Calculator
      views, unguarded `.keyboardType`) — fixed with `#if os(iOS)` guards + new
      `PlatformKeyboard.swift` (`decimalPadKeyboard()` cross-platform helper).
      **macOS now builds** (was broken at the last commit).

---

## Already done (verified this session, carried from prior agent)

- [x] pbxproj: `DSM5TR` classic folder ref `…205` + "in Resources" `…206` on the iOS
      target (lines 15/69/117/268). Built app contains `DSM5TR/`.
- [x] `Sources/iOS/DSMManual/DsmTopicLibrary.swift` (index load → dir-scan fallback,
      nameHits/contentHits/fullText cache, entriesBySpecialty).
- [x] `Sources/iOS/DSMManual/DsmManualViews.swift` (DsmManualView list+search,
      DsmTopicRow, DsmTopicDetailView).
- [x] `NurseVaultApp.swift`: `dsmLibrary` environment + `loadIfNeeded`.
- [x] `RootView.swift`: `SidebarItem.dsmManual`, sidebar row (badge), content case.
- [x] Bug #1 pragmatic patch in tree (pageSize 50M, thinMaterial) — superseded by
      Phase A clean removal.
- [x] Phase 1 data audit (all findings above are re-verified this session).

## Known quirks to keep in mind

- `DsmTopicDetailView.bodyText` currently renders **raw** `fullText` (incl. the
  `===` title line + `DSM-5-TR CONTENT:` label) — Merck's version uses
  `cachedBodyString` (header stripped). Fix in Phase A2-adjacent: make DSM's
  `bodyText` use `cachedBodyString ?? text` and extend its header-skip prefixes
  with `ICD-10-CM:` / `DSM-5-TR CONTENT:`.
- DSM search snippets are lowercase (built from `VaultSearch.normalize`-ed text) —
  same as Merck's existing behavior; consistent, not a new bug.
- `bodyText(for:)` in WatchDrugReference.swift is **shared** by drugs + Merck + (soon)
  DSM watch details — only add prefixes that DSM files carry.
- Watch index format (build_watch_reference.py): `<title>|<preview>|<start>|<end>|<extra>`,
  content = per-entry 8-byte LE size prefix + brotli(q11); `WatchReference` parses
  with `maxSplits: 4` and looks up `<rawValue>.index` / `<rawValue>.content`.
- DSM `DSM5TR_full/` and `DSM5TR/` are untracked in git (never committed).
- Do NOT run destructive git commands; working tree intentionally dirty.

## Build / device notes

- Schemes: `NurseVault` (iOS), `NurseVault Watch`, `NurseVault Watch Widget`,
  `NurseVaultCore`. Xcode 27.1 / Swift 6.4.
- watchOS 27.0 sims (Shutdown): Series 12 46mm `E7B2472A-9FEC-4B81-8F5D-965474CF678E`
  etc. No Simulator.app UI scripting — verify via `simctl install` / `simctl launch
  [--args]` / `simctl io screenshot` + the DEBUG jump hook (A3).
- `PBXFileSystemSynchronizedRootGroup` for Sources/{iOS,Watch,Widget}: new files
  under them are auto-included; no pbxproj edits needed for the dsm.* resources.
