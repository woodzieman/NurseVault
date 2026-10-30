# NurseVault Code Audit Report

**Date:** 2026-10-30
**Auditor:** LM Studio Bionic Agent
**Scope:** iOS/macOS/WatchOS Swift codebase (112 files, ~29,872 lines)

---

## 1. Executive summary

This audit identified **9 findings** across the NurseVault codebase after a fresh compiler pass and targeted source review. The project is generally well-structured with clean architecture and good use of modern Swift patterns. No critical crash-inducing bugs were confirmed after verification, though several concurrency warnings and code-quality issues warrant attention.

| Severity | Count | Key Areas |
|----------|-------|-----------|
| Critical | 0 | None verified |
| High | 2 | Main actor concurrency, force-unwraps |
| Medium | 4 | Logging, oversized files |
| Low | 3 | Unused results, TODOs |

### Top Priority Findings

1. **[High] Main-actor-isolated properties accessed from Sendable closure** — §3.1 — `Sources/iOS/DocDetailView.swift:160-162`
2. **[High] Force-unwrap of debounceTimer in onChange debounce** — §5.1 — `Sources/iOS/DocDetailView.swift:167`
3. **[Medium] Force-unwrap of contentData after assignment in WatchReferenceStore** — §5.2 — `Sources/Watch/WatchReferenceStore.swift:294`
4. **[Medium] Oversized calculator data file** — §9.1 — `Sources/iOS/Calculators/MedCalcData_Pediatrics.swift:1-7244`

---

## 2. Quick wins

### 2.1 Remove force-unwrap of debounceTimer
- **Location:** `Sources/iOS/DocDetailView.swift:167`
- **Action:** Guard against nil before `RunLoop.main.add`, or use optional chaining. 5 minutes.

### 2.2 Guard contentData force-unwrap in WatchReferenceStore
- **Location:** `Sources/Watch/WatchReferenceStore.swift:294`
- **Action:** Use `contentData?.count` or move NSLog inside assignment guard. 5 minutes.

### 2.3 Suppress or fix main-actor warnings in BookReaderView
- **Location:** `Sources/iOS/BookReader/BookReaderView.swift:61-63`
- **Action:** Mark `makeUIView` as `@MainActor` or isolate PDFView creation to main actor. 10 minutes.

### 2.4 Add #if DEBUG around NSLog statements
- **Location:** `Sources/Watch/WatchReferenceStore.swift:283-380`, `Sources/Watch/WatchDrugReference.swift:353-389`
- **Action:** Wrap existing #if DEBUG blocks consistently or replace with Logger. 15 minutes.

---

## 3. Concurrency

### 3.1 Main-actor-isolated properties accessed from Sendable closure
- **Location:** `Sources/iOS/DocDetailView.swift:160-162`
- **What:** `onChange(of: selectedFolderIndex)` closure captures `folderOptions`, `selectedSectionIndex`, `sections` which are main-actor-isolated, triggering compiler warnings.
- **Why:** Sendable closure may execute off-main, risking data races or compiler errors with stricter concurrency.
- **Action:** Make closure `@MainActor`, capture snapshot values, or move state mutation into `MainActor.run`.
- **Severity:** High

### 3.2 Main-actor-isolated initializer called in nonisolated context
- **Location:** `Sources/iOS/BookReader/BookReaderView.swift:61-63`
- **What:** `PDFView()` initializer and mutations of `document`/`autoScales` in `makeUIView` produce `call to main actor-isolated initializer` and mutation warnings.
- **Why:** `makeUIView` is not guaranteed main-actor-isolated; UIKit types require main actor.
- **Action:** Annotate `VaultPDFView.makeUIView` with `@MainActor` or wrap in `MainActor.assumeIsolated`.
- **Severity:** High

### 3.3 Timer scheduled and added to RunLoop without main-actor guarantee
- **Location:** `Sources/iOS/DocDetailView.swift:165-167`
- **What:** `Timer.scheduledTimer` created inside onChange, then `RunLoop.main.add(debounceTimer!, forMode: .common)`.
- **Why:** Timer creation may happen off main, and force-unwrap can crash if scheduling fails.
- **Action:** Schedule on main actor and safely unwrap.
- **Severity:** Medium

---

## 4. API modernity

### 4.1 No deprecated API usage detected in compiler warnings
- **Location:** N/A
- **What:** Build produced no deprecation warnings for iOS 17+ deployment target.
- **Why:** Project appears current.
- **Action:** Continue monitoring.
- **Severity:** Low

---

## 5. Bugs / logic errors

### 5.1 Force-unwrap of debounceTimer may crash
- **Location:** `Sources/iOS/DocDetailView.swift:167`
- **What:** `RunLoop.main.add(debounceTimer!, forMode: .common)` force-unwraps timer created on previous line.
- **Why:** If `Timer.scheduledTimer` returns nil (theoretically possible under memory pressure), crash occurs. Also hides potential nil path.
- **Action:** Use `if let timer = debounceTimer` or `guard let`.
- **Severity:** High

### 5.2 Force-unwrap of contentData after successful assignment
- **Location:** `Sources/Watch/WatchReferenceStore.swift:294`
- **What:** `NSLog("... loaded \(contentData!.count) bytes")` force-unwraps `contentData` immediately after `contentData = try Data(contentsOf: url)`.
- **Why:** Unnecessary force-unwrap; if assignment failed, code would have returned. Still defensive.
- **Action:** Use `contentData?.count ?? 0` or log before assignment.
- **Severity:** Medium

### 5.3 Unused result of operator '..<' warning
- **Location:** `Sources/iOS/Books/BooksView.swift:142`
- **What:** Compiler warns result of operator `..<` is unused.
- **Why:** Likely a stale expression or copy-paste artifact; may indicate dead code.
- **Action:** Verify `notesPreview` implementation; remove unused range if present.
- **Severity:** Low

---

## 6. Security

### 6.1 No hardcoded secrets found
- **Location:** N/A
- **What:** Grep for Bearer/apiKey/secret found no secrets in Sources.
- **Why:** Good.
- **Action:** None.
- **Severity:** Low

---

## 7. Performance

### 7.1 Oversized calculator data file
- **Location:** `Sources/iOS/Calculators/MedCalcData_Pediatrics.swift:1-7244`
- **What:** Single file contains 7,244 lines of static data.
- **Why:** Large file slows compilation, increases merge conflicts, hard to navigate.
- **Action:** Split into multiple files by sub-category or load from bundled JSON/resource.
- **Severity:** Medium

### 7.2 WatchReferenceStore loads entire content file into RAM
- **Location:** `Sources/Watch/WatchReferenceStore.swift:287`
- **What:** `Data(contentsOf:)` loads full content file up to 50 MB cap.
- **Why:** Watch RAM is limited; loading entire file may cause memory pressure when combined with other resources.
- **Action:** Keep current memory-mapped approach with size cap, or stream per entry.
- **Severity:** Medium

---

## 8. SwiftUI / UI

### 8.1 No SwiftUI-specific findings confirmed in this pass
- **Location:** N/A
- **What:** Quick scan found no modifier ordering or state-init issues in hot spots.
- **Action:** None for this audit.
- **Severity:** Low

---

## 9. Dead code / duplication / refactor

### 9.1 Oversized file >500 lines
- **Location:** `Sources/iOS/Calculators/MedCalcData_Pediatrics.swift:1-7244`
- **What:** 7,244 lines in single Swift file.
- **Why:** Difficult to maintain, slow builds.
- **Action:** Split into smaller modules or external data files.
- **Severity:** Medium

### 9.2 TODO marker present
- **Location:** `Sources/iOS/Calculators/MedCalcData_Pediatrics.swift:14`
- **What:** Comment `// TODO: Consider splitting this file into smaller modules or loading from external resource files`
- **Why:** Acknowledged tech debt.
- **Action:** Track in TODO.md and schedule refactor.
- **Severity:** Low

### 9.3 NSLog statements in production code paths
- **Location:** `Sources/Watch/WatchReferenceStore.swift:273,283,294,299,316,331,344,353,357,367,376,380`
- **What:** Multiple `NSLog` calls for diagnostics, some wrapped in `#if DEBUG`, some not.
- **Why:** Noise in production logs, potential PII leakage.
- **Action:** Migrate to `Logger` with privacy redaction and ensure DEBUG gating.
- **Severity:** Low

---

## 10. Cross-cutting recommendations

- Enforce `@MainActor` on all `UIViewRepresentable.makeUIView` / `updateUIView` for UIKit interop.
- Adopt consistent logging via `os.Logger` with `#if DEBUG` gating.
- Split calculator data files >1000 lines into resource bundles.
- Add unit tests for `VaultPDFView` and `WatchReferenceStore` loading paths.

---

## 11. What was NOT audited

- Metal kernels / domain-specific calculator algorithms
- Build settings, scheme configuration, Xcode project structure
- Third-party dependency internals
- Test coverage assessment
- Localization correctness
- Performance profiling with Instruments

---

## 12. Verification

- **§3.1** — Open `Sources/iOS/DocDetailView.swift`, lines 160-167. Confirmed `onChange` closure references `folderOptions`, `selectedSectionIndex`, `sections` and schedules `Timer`. Compiler warning reproduced in xcodebuild output.
- **§5.1** — Open `Sources/iOS/DocDetailView.swift`, line 167. Confirmed `RunLoop.main.add(debounceTimer!, forMode: .common)` force-unwrap.
- **§3.2** — Open `Sources/iOS/BookReader/BookReaderView.swift`, lines 61-63. Confirmed `pdfView.document = PDFDocument(data: data)` and `autoScales = true` in `makeUIView`. Compiler warnings reproduced.
- **§5.2** — Open `Sources/Watch/WatchReferenceStore.swift`, line 294. Confirmed `NSLog("... \(contentData!.count) ...")` force-unwrap after assignment.
- **§9.1** — `wc -l Sources/iOS/Calculators/MedCalcData_Pediatrics.swift` reports 7244 lines. Confirmed.
- **§9.2** — Open `Sources/iOS/Calculators/MedCalcData_Pediatrics.swift`, line 14. TODO comment confirmed.

---

*Report generated 2026-10-30. Overwrites previous snapshot.*
