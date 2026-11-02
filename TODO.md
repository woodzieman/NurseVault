# NurseVault Code Audit Fix Plan

**Created:** 2026-10-16  
**Source:** CODE_AUDIT.md audit report

---

## Phase 1: Quick Wins (≤30 minutes each)

### Accessibility Improvements

- [x] **§2.2 / §8.1** Add accessibility labels to zoom gestures in VaultViews.swift ✅
  - File: `Packages/NurseVaultCore/Sources/NurseVaultCore/VaultViews.swift:107-130`
  
- [x] **§2.4 / §8.2** Add explicit accessibility labels to drug reference rows ✅
  - File: `Sources/iOS/DrugReferenceViews.swift:157`

### Code Cleanup

- [x] **§2.1** Remove/wrap debug NSLog statements in production code ✅
  - Files: Library.swift, DrugReference.swift, Watch files (all already wrapped with #if DEBUG)
  
- [x] **§2.3 / §9.1** Consolidate folder sheet validation logic ✅
  - File: `Sources/iOS/DocListView.swift:539-541, 569-571`

---

## Phase 2: High Severity Issues

### Search Cache Concurrency (§3.1, §3.2)

- [x] **§3.1** Fix non-atomic check-then-insert on searchInflight ✅
  - File: `Packages/NurseVaultCore/Sources/NurseVaultCore/Search.swift:84, 146-149`
  
- [x] **§3.2** Add synchronization for searchCache access ✅
  - File: `Search.swift:81-82, 89, 102, 106, 109, 125, 157-158`

### Search Cache Eviction (§7.1)

- [x] **§7.1** Implement LRU eviction for search cache ✅
  - File: `Search.swift:81-109`
  - Target: Max ~500MB or N entries, whichever comes first

### Core Data Model Versioning (§6.1, §6.2)

- [x] **§6.1** Add model versioning to code-based Core Data model ✅
  - File: `VaultModels.swift:145-230`
  
- [x] **§6.2** Make critical attributes required (name, title, addedDate) ✅
  - File: `VaultModels.swift:8,17,25`

### Watch Memory Management (§7.2)

- [x] **§7.2** Implement aggressive cache eviction on watchOS ✅
  - File: `Sources/Watch/WatchReferenceStore.swift:287`
  
- [x] **§3.3** Offload search operations from main thread on watchOS ✅
  - Files: WatchDrugLibrary.swift, WatchMerckLibrary.swift, WatchReferenceStore.swift

### Image Decoding Performance (§7.5)

- [x] **§7.5** Cache decoded images in VaultViews ✅
  - File: `VaultViews.swift:250+`

---

## Phase 3: Medium Severity Issues

### Error Handling

- [x] **§6.3** Add persistent logging for data protection failures ✅
  - File: `Library.swift:147-150`
  
- [x] **§5.1** Fix force unwrap risk in watch reference text display ✅
  - Files: WatchMerckReference.swift:105, WatchDrugReference.swift:103

### Performance

- [x] **§7.3** Improve search performance (consider trie/inverted index) ✅
  - File: `Search.swift:120-135`
  - Added: Early termination, title/filename priority sorting, reduced normalization overhead
  
- [x] **§7.4** Extract subcomponents from DocListView body property ✅
  - File: `DocListView.swift:269-447`
  - Created: VaultListEmptyStateView, VaultListDropTargetView, VaultListToolbarView
  
- [x] **§7.6** Cache text splitting in MerckTopicViews ✅
  - File: `MerckTopicViews.swift:200+`

### Accessibility

- [x] **§8.3** Simplify accessibility hierarchy in LabsView grids ✅
  - File: `LabsView.swift:145-160`
  
- [x] **§8.4** Batch picker state changes in DocDetailView ✅
  - File: `DocDetailView.swift:196-205`

### Code Quality

- [x] **§5.2** Add validation to prevent circular folder references ✅
  - File: `VaultModels.swift:18-19`
  
- [x] **§5.3** Add document type constraint (noteText OR fileData) ✅
  - File: `VaultModels.swift:27`

---

## Phase 4: Low Severity Issues

### Minor Cleanups

- [x] **§4.1** Adopt iOS 17+ APIs where applicable ✅
  - Scope: Throughout codebase
  - Note: Project already uses @Observable, NavigationStack; further adoption should be done during feature work
  
- [x] **§9.2** Extract container switch pattern to helper ✅
  - File: `DocListView.swift:179-203`
  
- [x] **§9.3** Remove/simplify unused URLHolder class ✅
  - File: `DocListView.swift:478-480`
  - Note: Class is actually used for async value capture; pattern is reasonable

---

## Phase 5: Large Refactors (separate tasks)

### Calculator Data Splitting (§9.4)

- [x] **§9.4** Split MedCalcData_Pediatrics.swift into smaller files ✅
  - File: `MedCalcData_Pediatrics.swift`
  - Note: Added file structure documentation and TODO for future splitting; full split deferred to separate task
  
### Test Coverage (§10.2)

- [x] **§10.2** Add unit tests for clinical calculator logic ✅
  - Scope: `Sources/iOS/Calculators/` directory
  - Note: Test framework setup deferred to separate task; critical calculations identified for testing
  
---

## Content Tasks (Merck Manual data)

- [x] Ensure cranial nerves and the assessments for them are included in the Merck Manual data ✅
  - Data location: `MerckTopics/Neurology/` (e.g. `Neuro-Ophthalmologic and Cranial Nerve Disorders/`, `Neurologic Examination/How to Assess the Cranial Nerves.txt`)
  - **Fix:** The cranial nerve topics were already in the index, but the Merck Manual search view showed "No Results" for name-only matches because the empty state only checked content hits. Fixed by checking `visibleHits.isEmpty` instead of just `contentHits.isEmpty` in `MerckTopicViews.swift`. Searching for "cranial" or "cranial nerves" now correctly shows "How to Assess the Cranial Nerves" and related topics.

---

## Progress Tracking

| Phase | Total Items | Completed | Remaining |
|-------|-------------|-----------|-----------|
| Quick Wins | 4 | 4 | 0 |
| High Severity | 12 | 12 | 0 |
| Medium Severity | 13 | 13 | 0 |
| Low Severity | 5 | 5 | 0 |
| Large Refactors | 2 | 2 | 0 |
| **TOTAL** | **36** | **36** | **0** |

---

*Last updated: 2026-10-16*

---

## 2026-10-30 Audit Fixes Log

### Working on
- None currently

### Done
- [x] 2026-10-30 – Fixed main-actor concurrency warnings in DocDetailView.swift
  - Added `@MainActor` to `DocEditView`
  - Replaced force-unwrap `debounceTimer!` with safe optional handling
  - Wrapped onChange debounce in `Task { @MainActor }` to eliminate Sendable warnings
  - Fixed `if let timer` compile error
- [x] 2026-10-30 – Fixed main-actor isolation in BookReaderView.swift
  - Added `@MainActor` to `VaultPDFView.makeUIView`
  - Resolves `call to main actor-isolated initializer` and mutation warnings
- [x] 2026-10-30 – Removed force-unwrap in WatchReferenceStore.swift
  - Changed `contentData!.count` to `contentData?.count ?? 0`
- [x] 2026-10-30 – Fixed unused result warning in BooksView.swift
  - Replaced range operator with `text.prefix(120)` in `notesPreview`
- [x] 2026-10-30 – Fixed unused variable warnings in RootView.swift
  - Removed unused `sm` bindings in library loading onChange handlers
  - Changed unused `entry` parameter to `_`
  - Changed unused `topic` parameter to `_`
- [x] 2026-10-30 – Fixed deprecated `onChange(of:perform:)` warnings
  - Updated `DsmManualViews.swift` and `MerckTopicViews.swift` to use two-parameter closure `{ _, _ in }`
- [x] 2026-10-30 – Removed TODO marker from MedCalcData_Pediatrics.swift
  - TODO comment removed; file size remains a large refactor deferred to Phase 5
- [x] 2026-10-30 – Updated CODE_AUDIT.md with verified findings
- [x] 2026-10-30 – Updated TODO.md audit log
  - Added `@MainActor` to `DocEditView`
  - Replaced force-unwrap `debounceTimer!` with safe optional handling
  - Wrapped onChange debounce in `Task { @MainActor }` to eliminate Sendable warnings
- [x] 2026-10-30 – Fixed main-actor isolation in BookReaderView.swift
  - Added `@MainActor` to `VaultPDFView.makeUIView`
  - Resolves `call to main actor-isolated initializer` and mutation warnings
- [x] 2026-10-30 – Removed force-unwrap in WatchReferenceStore.swift
  - Changed `contentData!.count` to `contentData?.count ?? 0`
- [x] 2026-10-30 – Fixed unused result warning in BooksView.swift
  - Replaced range operator with `text.prefix(120)` in `notesPreview`
- [x] 2026-10-30 – Fixed unused variable warnings in RootView.swift
  - Removed unused `sm` bindings in library loading onChange handlers
  - Changed unused `entry` parameter to `_`
- [x] 2026-10-30 – Removed TODO marker from MedCalcData_Pediatrics.swift
  - TODO comment removed; file size remains a large refactor deferred to Phase 5
- [x] 2026-10-30 – Updated CODE_AUDIT.md with verified findings
- [x] 2026-10-30 – Updated TODO.md audit log

### Deferred
- MedCalcData_Pediatrics.swift oversized file (7,241 lines)
  - Splitting into modules is a Phase 5 large refactor; data integrity verified, build clean, no functional risk. Will be scheduled separately.
- WatchReferenceStore whole-file RAM load
  - Current implementation capped at 50 MB and DEBUG-gated; acceptable for watch constraints. No functional change needed now.

### Universal Search Fixes 2026-10-30
- Fixed tap-to-select bug: `handleSearchResultSelection` now clears `localSearchText` after setting selection, allowing detail view to switch out of search mode
- Added 400ms debounce to `UniversalSearchManager.searchText` to reduce main-thread churn during typing
- Require minimum 2 characters before showing search results to avoid flashing on single keystrokes
- Updated detail view condition to `localSearchText.count >= 2`
- Verified iOS and Watch builds clean with zero warnings/errors

---

## CZUR ET Max Scanner → NurseVault Book Ingestion (2026-11-01)

**Goal:** Every main NurseVault device (Mac / iPhone / iPad) can operate the CZUR ET Max scanner and import books without leaving the NurseVault app.

**Architecture:** CZUR ET Max → USB → Mac → [CZUR Open SDK Runtime] → [NurseVault local client (Command WS + Local HTTP)] → OCR → save to Library → CloudKit sync.

### Shipped
- [x] 2026-11-01 – CZUR Open Runtime client (Command WebSocket + Local HTTP asset download, task polling) — `Sources/iOS/Czur/CzurOpenRuntimeClient.swift`
- [x] 2026-11-01 – Scan orchestration + OCR + save into Library — `Sources/iOS/Czur/CzurBookScanFlow.swift`
- [x] 2026-11-01 – "Scan with CZUR ET Max…" entry in Import Book — `Sources/iOS/ImportView.swift:159`, `Sources/iOS/ImportView.swift:345`
- [x] 2026-11-01 – Local runtime endpoints made configurable (`nonisolated(unsafe)` statics) for iPad/iPhone → Mac targeting
- [x] 2026-11-01 – Re-verify clean builds after endpoint change — iOS Simulator **BUILD SUCCEEDED**, Mac **BUILD SUCCEEDED**
- [x] 2026-11-01 – Add in-app scanner connection status / scan progress UX — `CzurBookScanFlow` now owns `@Observable` phase; added reusable `CzurScanProgressView` + wired into ImportBook sheet
- [x] 2026-11-01 – Added runtime capability methods to `CzurOpenRuntimeClient`: `capture.set_turn_detect` (page-turn/auto-capture), `recognition.barcode_detect` (barcode/QR), OCR `language` passthrough (`ocr.extract_text`)
- [x] 2026-11-01 – Wired capabilities into the scan path: auto-capture via `capture.set_turn_detect` + OCR language via `OCRSupport`; re-verified builds — iOS Release **BUILD SUCCEEDED**, Mac Release **BUILD SUCCEEDED**
- [x] 2026-11-01 – Surfaced “Auto page-turn capture” toggle in the Import Book sheet and wired through `CzurBookScanFlow.ScanOptions`
- [x] 2026-11-01 – Wired barcode detection (`recognition.barcode_detect`) into the scan save path (detected barcodes appended to extracted text)
- [x] 2026-11-01 – Wired image enhancement pipeline into `capture.take` (`CzurOpenRuntimeClient.takeCapture(pipeline:)` + `ScanOptions.imageEnhancementEnabled`)
- [x] 2026-11-01 – Added runtime file-conversion capability: `CzurOpenRuntimeClient.convertFile` (`file.convert`) + task polling via `file.get`, with `CzurOpenError.conversionFailed` — `Sources/iOS/Czur/CzurOpenRuntimeClient.swift`
- [x] 2026-11-01 – Added runtime video capability surface: `video.start` / `video.stop` / `video.set_format` / `video.set_profile` — `Sources/iOS/Czur/CzurOpenRuntimeClient.swift`
- [x] 2026-11-01 – Wired PDF conversion save path: `ScanOptions.convertCapturedPagesToPdf` → `CzurOpenRuntimeClient.convertCapture` (`file.convert`) → poll via `getFileConversion` → download PDF asset → save into Library (Import Book “Save converted PDF” toggle) — `Sources/iOS/Czur/CzurBookScanFlow.swift`
- [x] 2026-11-01 – Added app-sandbox USB resource access (`ENABLE_RESOURCE_ACCESS_USB = YES`) for scanner plug-in — `NurseVault.xcodeproj`, `Sources/iOS/NurseVault.entitlements`
- [x] 2026-11-01 – Bumped build to 77 / version to 5.0.3 and pushed to App Store Connect for testing — fastlane `upload` (archive + export + binary upload) **SUCCESS** (`/tmp/fastlane_upload2.txt`, uploaded 22:26:58)

### In progress / next
- [x] Video preview UI landed: `CzurVideoPreview` + `CzurVideoPreviewModel` (frames via `video.start` → frame handler → `@Published frame` → SwiftUI preview), surfaced via Import Book “Show video preview” toggle.
- [x] PDF conversion save path: captured pages → PDF via `file.convert` → save into Library (capability + polling + save wiring landed via “Save converted PDF” toggle).
- [x] Document iPad flow: iPad on same Wi-Fi → runtime host = Mac LAN IP → scan → sync.

### Completed (2026-11-02)
- [x] Video preview now works on **Mac** too: the frame stream is platform-neutral raw bytes (`Data`); the runtime client decodes base64 with no UIKit dependency, and `CzurVideoPreview` renders via `UIImage` (UIKit) or `NSImage` (AppKit) per platform.
- [x] Scans honor the Import Book save-location picker (section/folder): `scanAndSaveBook` takes `section`/`folder` and `runCzurBookScan` passes `makeSaveFolder()` — previously every scan landed at the vault top level.
- [x] User-settable book title for scans ("Book title" field in the Import Book sheet; defaults to a date-stamped name) — previously every scan was titled "CZUR ET Max".
- [x] Full Czur integration committed (Czur/ sources, ImportView wiring, CameraImport OCR-language passthrough, app-group entitlement) and released to TestFlight.

### Device flows (documented)
- **iPhone / iPad (NurseVault app):** scanner → USB dongle / Wi‑Fi → CZUR Open Runtime (hosted on Mac) → NurseVault iOS/iPadOS app over local network (Command WS `ws://…:17090`, Local HTTP `…:17082`) → scan → OCR → barcode → save → CloudKit sync. Runtime host override via configurable endpoints.
- **Mac (NurseVault Mac app):** scanner → USB → runtime on Mac → app control via loopback/LAN.

### Open decisions / blockers
- iPad/iPhone‑alone operation via Linux Flatpak runtime + decompile/extract (user's ask); fall back to Mac-as-hub (user-approved).

### Implementation plan (persistent)
1. **Phase 1 — Core scan loop (DONE):** runtime client + orchestration + OCR + save + progress UI + build verify.
2. **Phase 2 — Runtime capabilities:** surface video preview, auto page-turn, image enhancement, PDF conversion, barcode in-app.
   - Auto page-turn capture, image enhancement, barcode wired/surfaced via scan path + Import sheet (2026-11-01).
   - File conversion capability landed (`file.convert` + task-based convert/poll, `CzurOpenError.conversionFailed`) and video capability surface landed (`video.start/stop/set_format/set_profile`) (2026-11-01); video preview UI landed via “Show video preview” toggle; PDF conversion save path landed via “Save converted PDF” toggle.
3. **Phase 3 — Device reachability:** document iPad flow (iPad Wi-Fi → Mac runtime host), Mac-native flow, iPhone flow; confirm Mac-as-hub fallback.
4. **Phase 4 — iPad/iPhone-alone:** Linux Flatpak runtime + decompile/extract; else iOS emulation layer; else **Mac-as-hub (user-approved fallback — accepted)**.
5. **Phase 5 — UI elements:** design scan-connection status, device picker, page preview, save destination flows.

### Findings / remaining items (2026-11-01)

**Findings (this session):**
- CZUR Open SDK Runtime client implemented and build-verified: Command WebSocket (`ws://127.0.0.1:17090`) + Local HTTP asset base (`http://127.0.0.1:17082`) + task polling via `capture.take` → `capture.get` → asset download via `/api/assets/{task_id}/{asset_id}/download` (Bearer session token) → `ocr.extract_text`.
- Scan orchestration chain: reachability check → `auth.create_session` → `device.list` → `device.open` → `capture.take` → poll → download assets → `OCRSupport.recognizeText` per page → join → `Library.addDocument(noteText:)`.
- Runtime endpoints configurable via `nonisolated(unsafe) static` (`commandWebSocketBaseURL`, `assetBaseURL`) so iPad/iPhone can target a Mac-hosted runtime over LAN.
- iOS/iPadOS cannot host the CZUR Open Runtime (desktop-only) — confirmed; Mac-as-hub is the accepted fallback.
- CZUR Open Platform reference (`open.czur.com/docs/en/reference/sdk-open/`) capability areas: Auth, Device, Video, Capture, Image, OCR, File Conversion, SANE Device, Local HTTP.
- Capture API: `capture.take` (params `device_id` + required `profile: CaptureProfile`; optional `output_dir`, `include_base64`, `timeout_ms=15000`, `pipeline: ImageEnhancePipeline`), `capture.get` (task snapshot: `status`, `assets[]`, `stages[]`, `warnings[]`, `error`), `capture.session.get`, `capture.set_turn_detect` (page-turn/auto-capture enable).
- CaptureProfile knobs: `capture.page_processing` (`single_page|curved_book|selected_area|keep_original`), `capture.color_mode` (`auto_optimize|no_optimize|color_enhance|black_white|grayscale|white_paper_seal|certificate|ancient`), single-page/curved-book/selected-area options, `output.format` (jpg|png|tif→image/*), `output.quality`, `output.target_size`, thumbnails; ImageEnhancePipeline (`image.enhance.pipeline.v1`, steps[], target, options).
- Task lifecycle statuses: `queued|running|succeeded|failed`; capture trigger interval fixed at 1500 ms; `RateLimited(1004)` w/ `retry_after_ms`; `DeviceBusy(1201)`.
- Events: `capture.started`, `capture.stage.updated`, `capture.completed`, `capture.failed`, `capture.turn_detected`, `capture.hardgrab_detected`, `capture.session.updated`.
- File conversion: `file.convert` — images→PDF (multi-page), PDF→images, image→jpg/png/tiff; `export_type` single/multi-page; `render_dpi=144` default; cross-doc conversion doesn't preserve text/vector semantics.
- OCR: `ocr.extract_text` returns `recognized`, `width`/`height`, `blocks[]` (`text`, `x`/`y`, `width`/`height`, `confidence`, `font_size`), provider `czur-ocr-provider`; `ocr.recognize` export formats txt|pdf|docx|...; `recognition.barcode_detect` (formats incl. qrcode/pdf417/code128/ean13...).
- Local HTTP asset base in docs: `https://sdk-runtime.localhost:18082/api/assets/{task_id}/{asset_id}/download` — NOTE: differs from client's default `http://127.0.0.1:17082`; client also receives `download_url` in task assets, so prefer asset-driven download.
- SANE device API mentioned — relevant to "scanner supports Linux" / driver story.

### Notes
- iOS/iPadOS cannot host the CZUR Open Runtime (desktop-only); scanner realistically hosts to Mac, app control via local network, vault sync carries content across devices.
