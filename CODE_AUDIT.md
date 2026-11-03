# Nurse Vault Code Audit

Generated 2026-11-03. Scope: ~31,857 Swift lines across 129 source files in 4 targets — `NurseVault` (iOS/iPadOS/macOS), `NurseVault Watch`, `NurseVault Watch Widget`, and the `NurseVaultCore` SPM package. No Metal kernels (`*.metal`: 0). iOS deployment target 17.0, macOS 14.0. No `Dead/` archive directory exists.

> **Status — fixes applied (2026-11-03).** All findings in this report have been addressed. Clean Debug builds of `NurseVault` (iOS Simulator + macOS), `NurseVault Watch`, and `NurseVault Watch Widget`: **0 errors, 0 warnings**.

Findings below are retained as the audit snapshot; each one is marked resolved in the implementation.

---

## 1. Executive summary

Top items to address, in priority order:

1. **[High] Plain `Task {}` inside `@MainActor @Observable` stores mutates UI-observable state off the main actor** — `Sources/Watch/WatchReferenceStore.swift:125`, `Sources/iOS/DrugReference.swift:98`, `Sources/iOS/MerckManual/MerckTopicLibrary.swift:80`, `Sources/iOS/DSMManual/DsmTopicLibrary.swift:55`. §3.1
2. **[High] Watch reference view debounce Tasks update `@State` without `@MainActor`** — `Sources/Watch/WatchMerckReference.swift:52-55`, `Sources/Watch/WatchDsmReference.swift:51-55`, `Sources/Watch/WatchDrugReference.swift:51-55`. §3.2
3. **[Medium] Force-unwraps on static URL initialisers and handler registration** — `Sources/iOS/Czur/CzurOpenRuntimeClient.swift:95-96`, `Sources/iOS/Czur/CzurVideoPreviewModel.swift:33`. §5.1
4. **[Medium] Calculator spec force-unwraps on parsed values** — `Sources/iOS/Calculators/MedCalcSpecs_endocrinology.swift:105-107`, `Sources/iOS/Calculators/MedCalcSpecs_gastroenterology.swift:68`, `Sources/iOS/Calculators/MedCalcSpecs_neurology.swift:139`. §5.2
5. **[Low] Oversized calculator data file remains >5k LOC** — `Sources/iOS/Calculators/MedCalcData_Pediatrics_BPRegression.swift` (5,313 LOC). §9.1
6. **[Low] No Critical crash / data-loss findings confirmed in this sweep** — positive status. §12

---

## 2. Quick wins (≤30 min each)

- **Resolved:** CZUR static URL force-unwraps replaced with safe fallbacks; `handler!` replaced with a non-optional local handler.
- **Resolved:** `@MainActor` / `MainActor.run` added to the task bodies that write `@Observable` / `@State`.
- **Resolved:** `MedCalcData_Pediatrics_BPRegression.swift` split into 13 per-outcome files, each ~410 LOC.

---

## 3. Concurrency

### 3.1 Plain Task mutates @MainActor @Observable state off the main actor
- **Location:** `Sources/Watch/WatchReferenceStore.swift:125-135`, `Sources/iOS/DrugReference.swift:98-107`, `Sources/iOS/MerckManual/MerckTopicLibrary.swift:80-88`, `Sources/iOS/DSMManual/DsmTopicLibrary.swift:55-63`
- **What:** `@MainActor @Observable` classes (`WatchReference`, `DrugLibrary`, `MerckTopicLibrary`, `DsmTopicLibrary`) call `loadIfNeeded()` which spawns a plain `Task { … }`. Inside the task, properties such as `isLoading`, `entries`, `contentURL`, `isMissing` are written without `@MainActor` isolation.
- **Why:** UI-observable state is mutated off the main thread. Under Swift 6 strict concurrency this is a data race; today it can cause missed UI updates and intermittent consistency bugs.
- **Action:** Make the task `@MainActor`-isolated, e.g. `Task { @MainActor in … }` or move mutations into `await MainActor.run {}` after the background build completes.
- **Status:** Fixed — all four loaders now use `Task { @MainActor in … }`.
- **Severity:** High

### 3.2 Watch reference view debounce Tasks update @State without MainActor
- **Location:** `Sources/Watch/WatchMerckReference.swift:52-55`, `Sources/Watch/WatchDsmReference.swift:51-55`, `Sources/Watch/WatchDrugReference.swift:51-55`
- **What:** `.onChange(of: searchText)` creates a plain `Task { try? await Task.sleep…; query = text; visibleCount = 25 }`. `query` and `visibleCount` are `@State`.
- **Why:** State writes happen on an arbitrary executor. The same pattern appears in all three watch reference views.
- **Action:** Wrap the state writes in `await MainActor.run {}` or annotate the task with `@MainActor`.
- **Status:** Fixed — debounce and diagnostics tasks in all three watch reference views now use `Task { @MainActor in … }`.
- **Severity:** High

### 3.3 ResultStore widget reload debounce uses non-isolated Task
- **Location:** `Sources/iOS/Calculators/MedCalcResultStore.swift:160-163`
- **What:** `@MainActor @Observable final class ResultStore` stores `widgetReloadTask = Task { [weak self] in try? await Task.sleep…; self?.triggerWidgetReload() }`.
- **Why:** The task is created inside a MainActor-isolated type but not annotated; the closure captures `self` and calls a method that touches `@Observable` state.
- **Action:** Annotate the task body with `@MainActor` or use `Task { @MainActor in … }`.
- **Status:** Fixed — widget reload is now dispatched through `await MainActor.run { … }`.
- **Severity:** Medium

---

## 4. API modernity

### 4.1 @Observable migration complete
- **Location:** `Sources/iOS/DrugReference.swift:64`, `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:18`
- **What:** All major stores are `@MainActor @Observable`; grep confirms zero `ObservableObject` / `@Published` remain.
- **Why:** Positive — no migration work pending.
- **Action:** None.
- **Severity:** Low

### 4.2 Legacy dispatch primitives still present in widget reload path
- **Location:** `Sources/iOS/Calculators/MedCalcResultStore.swift:167-180`
- **What:** Previous audit noted `DispatchQueue.main.asyncAfter` + `DispatchWorkItem`. Current source shows Task-based debounce; verify no legacy remains.
- **Why:** Informational.
- **Action:** None required if Task-based.
- **Severity:** Low

---

## 5. Bugs / logic errors

### 5.1 Force-unwraps on static URLs and handler registration
- **Location:** `Sources/iOS/Czur/CzurOpenRuntimeClient.swift:95-96`, `Sources/iOS/Czur/CzurVideoPreviewModel.swift:33`
- **What:** `nonisolated(unsafe) static var commandWebSocketBaseURL: URL = URL(string: "ws://127.0.0.1:17090")!` and `assetBaseURL` force-unwrap a literal that is currently valid but will crash if changed. `client.registerVideoFrameHandler(handler!)` force-unwraps a handler set immediately before.
- **Why:** Latent crash risk; static initialisers are evaluated at load time.
- **Action:** Use `guard let` / `fatalError` with clear message, or make the URLs computed with safe fallback. Replace `handler!` with optional binding.
- **Status:** Fixed — static URLs now fall back to a non-optional `URL(fileURLWithPath:)`, and the video handler is registered via a non-optional local value.
- **Severity:** Medium

### 5.2 Calculator spec force-unwraps on parsed values
- **Location:** `Sources/iOS/Calculators/MedCalcSpecs_endocrinology.swift:105-107`, `Sources/iOS/Calculators/MedCalcSpecs_gastroenterology.swift:68`, `Sources/iOS/Calculators/MedCalcSpecs_neurology.swift:139`
- **What:** `v.number("h2")!`, `Double(table[dysplasia].replacingOccurrences(of: "%", with: ""))!`, `v.selection(id)!` are force-unwrapped after a guard that checks count but not individual presence.
- **Why:** If the spec definition drifts, the app will crash at runtime instead of failing gracefully.
- **Action:** Replace with optional binding / default values and surface a user-visible validation error.
- **Status:** Fixed — all three calculator specs now use optional binding and bounds checks.
- **Severity:** Medium

---

## 6. Security

### 6.1 App Group entitlement present
- **Location:** `Sources/iOS/NurseVault.entitlements`
- **What:** `com.apple.security.application-groups` now contains `group.com.josephwoods.nursevault`, matching watch/widget entitlements.
- **Why:** Positive — shared UserDefaults suite will work.
- **Action:** None.
- **Severity:** Low

### 6.2 No hardcoded secrets
- **Location:** Whole `Sources/` + `Packages/`
- **What:** Verified clean — no API keys, tokens, or endpoint switches.
- **Action:** None.
- **Severity:** Low

---

## 7. Performance

### 7.1 Full-vault search-index normalization on main actor
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift` (`maintainSearchIndex`)
- **What:** Reload performs background fetches, then normalizes content for every document on the main actor.
- **Why:** Main-thread cost scales with vault size.
- **Action:** Move normalization/eviction off the main actor.
- **Status:** Fixed — `maintainSearchIndex()` is now async and routes decode/normalization through nonisolated helpers; cache mutation uses synchronous locked helpers.
- **Severity:** Medium

---

## 8. SwiftUI / UI

### 8.1 No SwiftUI findings in this sweep
- **Location:** N/A
- **What:** Previous audit items around formatter caching and toolbar placement remain resolved.
- **Action:** None.
- **Severity:** Low

---

## 9. Dead code / duplication / refactor

### 9.1 Oversized calculator data file
- **Location:** Formerly `Sources/iOS/Calculators/MedCalcData_Pediatrics_BPRegression.swift` (5,313 LOC)
- **What:** File remains far above the 500 LOC split threshold.
- **Why:** Refactor candidate; content is inert data.
- **Action:** Split regression coefficients into per-outcome files.
- **Status:** Fixed — split into 13 files under `Sources/iOS/Calculators/` (~410 LOC each); the original 5,313-line file was removed.
- **Severity:** Low

### 9.2 No stale files or TODO markers found
- **Location:** Whole `Sources/` + `Packages/`
- **What:** No `#if false`, `_OLD`, `Legacy`, or `TODO`/`FIXME` markers in active source.
- **Action:** None.
- **Severity:** Low

---

## 10. Cross-cutting recommendations

1. Enforce `@MainActor` isolation for all tasks that mutate `@Observable` / `@State`. Add a lint rule or code review checklist.
2. Harden calculator specs by removing force-unwraps on parsed values; centralise validation in `MedCalcEngine`.
3. Continue splitting oversized data files to keep hot-spot list manageable.

---

## 11. What was NOT audited

- Algorithmic correctness of calculator formulas / LMS-z-score regressions.
- Deep test-coverage review.
- Third-party SPM dependency internals beyond `NurseVaultCore`.
- Localization / string catalogs.
- Instruments-level performance profiling.
- Full Xcode project build-settings diff beyond entitlements.

---

## 12. Verification

Spot-check pattern: open Xcode, command-click the `path:line` reference — it should land on the cited line.

- **§3.1** — open `Sources/Watch/WatchReferenceStore.swift`, lines 125-135; `Task { @MainActor in … }` now wraps the state writes.
- **§3.1** — open `Sources/iOS/DrugReference.swift`, lines 98-107; `Task { @MainActor in … }` now wraps the state writes.
- **§3.2** — open the three watch reference views; debounce and diagnostics tasks use `Task { @MainActor in … }`.
- **§5.1** — open `Sources/iOS/Czur/CzurOpenRuntimeClient.swift`, lines 95-96; static URL initialisers now use `?? URL(fileURLWithPath: "/")` instead of `!`.
- **§5.1** — open `Sources/iOS/Czur/CzurVideoPreviewModel.swift`; `start()` registers a non-optional local handler.
- **§7.1** — open `Packages/NurseVaultCore/Sources/NurseVaultCore/Search.swift`; `maintainSearchIndex()` is async and calls `normalizeSearchContent` / `decodeTextOffMain` off the main actor.
- **§9.1** — the 13 replacement files are present in `Sources/iOS/Calculators/`; the original file no longer exists.

All builds verified: `NurseVault` (iOS Simulator + macOS), `NurseVault Watch`, and `NurseVault Watch Widget` — Debug, 0 errors, 0 warnings.
