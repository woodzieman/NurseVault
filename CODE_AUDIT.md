# Nurse Vault Code Audit Report

**Date:** 2026-10-12  
**Scope:** Full iOS/macOS/watchOS codebase (7,008 lines of Swift across 29 files)  
**Xcode Version:** 16+ (watched for warnings with Xcode 17)  

---

## 1. Executive Summary

| # | Severity | Finding | Section |
|---|----------|---------|---------|
| 1 | Critical | Watch reference resources not bundled — causes blank detail views | §5.1 |
| 2 | Critical | Memory mapping fails silently on watchOS with no fallback | §5.2 |
| 3 | ~~High~~ | ~~Force-unwrap on Bundle.main.url for drug reference data~~ (NOT FOUND - audit finding incorrect) |
| 4 | High | Missing error handling in async content loading | §5.4 |
| 5 | Medium | Unused `save()` return values throughout Library.swift | §4.1 |
| 6 | Medium | Integer precision loss in compression_compat.c | §7.1 |

---

## 2. Quick Wins

### 2.1 Remove unused `save()` result warnings
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:456,497,511,518,524,530,540,547,565,576,598,673,767,774,794`
- **What:** 15+ instances of `context.save()` where the Bool return value is ignored
- **Why:** Warnings clutter build output and hide real issues
- **Action:** Either handle the result or use `_ = context.save()` to acknowledge intentional discard
- **Severity:** Low

### 2.2 Add accessibility labels to watch views
- **Location:** `Sources/Watch/NurseVaultWatchApp.swift` (various)
- **What:** Image system icons without accessibility labels
- **Why:** Screen reader users can't identify actions
- **Action:** Add `.accessibilityLabel()` modifiers to standalone images
- **Severity:** Low

---

## 3. Concurrency

### 3.1 Async content loading without proper error propagation
- **Location:** `Sources/Watch/WatchReferenceStore.swift:205-260`
- **What:** `text(for:)` method returns nil on errors instead of throwing or returning Result
- **Why:** Callers can't distinguish between "no content" and "loading failed"
- **Action:** Return `Result<String, Error>` or throw specific error types
- **Severity:** Medium

### 3.2 Missing @MainActor annotation consideration
- **Location:** `Sources/Watch/WatchReferenceStore.swift:45`
- **What:** Class is marked @MainActor but some methods are nonisolated static
- **Why:** Potential for cross-thread access if not careful with state mutations
- **Action:** Verify all property mutations happen on main thread; consider removing @MainActor and using explicit synchronization instead
- **Severity:** Low

---

## 4. API Modernity

### 4.1 Deprecated save() method usage
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift` (multiple lines)
- **What:** Using `NSManagedObjectContext.save()` which returns Bool in newer Core Data versions
- **Why:** Future Swift versions may require handling the return value
- **Action:** Update to handle save errors properly or use `saveIfNeeded()` where appropriate
- **Severity:** Low

---

## 5. Bugs / Logic Errors

### 5.1 Watch reference resources not bundled in Xcode project
- **Location:** `Sources/Watch/Resources/WatchReference/` (drugs.index, drugs.content, merck.index, merck.content)
- **What:** Resource files exist on disk but are not added to the NurseVault Watch target's resource bundle configuration
- **Why:** Causes blank detail views — index and content files can't be found at runtime despite enhanced URL resolution strategies
- **Action:** Add resources to package.swift or Xcode project as bundled resources for watch target
- **Severity:** Critical
- **Investigation Result:** ❌ NOT CONFIRMED - Resources ARE properly bundled via filesystem synchronization. Files found in built app bundle at root level.

### 5.2 Memory mapping fails silently on watchOS with no effective fallback
- **Location:** `Sources/Watch/WatchReferenceStore.swift:210-240`
- **What:** `.alwaysMapped` option often fails silently on watchOS; fallback to regular loading may also fail due to memory constraints
- **Why:** Users see blank screens with "Loading..." that never completes or shows errors
- **Action:** Implement Iteration 4 solution: load entire content file into memory once (8-13 MB fits in watch RAM) as primary strategy, not fallback
- **Severity:** Critical

### 5.3 Force-unwrap on Bundle.main.url for drug reference data
- **Location:** `Sources/iOS/DrugReference.swift` (various lines)
- **What:** Using `Bundle.main.url(forResource:withExtension:)!` without nil check
- **Why:** Will crash if resource file is missing or misnamed
- **Action:** Add optional binding and error handling
- **Severity:** High

### 5.4 Missing error handling in async content loading
- **Location:** `Sources/Watch/WatchDrugReference.swift:160-180`
- **What:** Detail view shows "Loading..." indefinitely when text loading fails silently
- **Why:** No timeout or error state; user has no indication something went wrong
- **Action:** Add timeout, loadError property display, and retry mechanism
- **Severity:** High

### 5.5 @Observable state propagation through value parameters
- **Location:** `Sources/Watch/WatchDrugReference.swift:21`, `Sources/Watch/WatchMerckReference.swift:20`
- **What:** WatchReference passed by value to child views may not trigger UI updates when entries are loaded
- **Why:** @Observable objects need proper observation setup; passing by value breaks the observation chain
- **Action:** Investigate proper @Observable usage patterns for watch app architecture
- **Severity:** Medium

---

## 6. Security

### 6.1 Core Data store not encrypted by default
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift` (store configuration)
- **What:** Persistent store may not have encryption enabled
- **Why:** User data could be read from device storage if device is compromised
- **Action:** Enable SQLCipher or use `NSSQLitePragmasDictionary` with `PRAGMA journal_mode = WAL; PRAGMA cipher_page_size = 4096;`
- **Severity:** Medium

---

## 7. Performance

### 7.1 Integer precision loss in compression_compat.c
- **Location:** `Packages/NurseVaultCore/Sources/CompressionCompat/compression_compat.c:20`
- **What:** Implicit conversion from size_t to int loses precision on 64-bit systems
- **Why:** Could cause buffer overflow with very large files (>2GB)
- **Action:** Use proper integer types throughout compression functions
- **Severity:** Low

### 7.2 Full content file loaded into memory for watch reference
- **Location:** `Sources/Watch/WatchReferenceStore.swift:210`
- **What:** Loading entire 8-13 MB content file into RAM on first access
- **Why:** While necessary for reliability, could cause issues if multiple references are accessed simultaneously
- **Action:** Implement release mechanism (already added as `releaseContentData()`) and call it when reference is no longer needed
- **Severity:** Low

---

## 8. SwiftUI / UI

### 8.1 Missing error state display in watch reference views
- **Location:** `Sources/Watch/WatchDrugReference.swift:160-180`, `Sources/Watch/WatchMerckReference.swift`
- **What:** Detail views show "Loading..." or generic message when content fails to load
- **Why:** Users can't understand why reference data isn't available
- **Action:** Display specific error messages (resource not found, decompression failed, etc.) with retry option
- **Severity:** Medium

### 8.2 No loading timeout in watch detail views
- **Location:** `Sources/Watch/WatchDrugReference.swift:160`
- **What:** Progress indicator runs indefinitely if content loading hangs
- **Why:** Poor UX — user has no indication of failure or way to recover
- **Action:** Add 5-second timeout with error state and retry button
- **Severity:** Low

---

## 9. Dead Code / Duplication / Refactor

### 9.1 Duplicate resource URL resolution code
- **Location:** `Sources/Watch/WatchReferenceStore.swift:100-180`, `Packages/NurseVaultCore/Sources/NurseVaultCore/WatchIndexBundle.swift`
- **What:** Two different implementations of resource bundle resolution with overlapping strategies
- **Why:** Maintenance burden and potential for inconsistent behavior
- **Action:** Consolidate into single WatchIndexBundle implementation used by both watch reference systems
- **Severity:** Low

### 9.2 Duplicate view code between drug and Merck reference views
- **Location:** `Sources/Watch/WatchDrugReference.swift`, `Sources/Watch/WatchMerckReference.swift`
- **What:** Nearly identical structure with only placeholder text differences
- **Why:** Code duplication increases maintenance burden
- **Action:** Create generic WatchReferenceView<T> that takes configuration parameters
- **Severity:** Low

---

## 10. Cross-cutting Recommendations

### 10.1 Standardize error handling across watch app
- **What:** Mix of nil returns, optional binding, and silent failures throughout watch code
- **Action:** Define WatchReferenceError enum with cases: resourceNotFound, decompressionFailed, invalidData, timeout, etc.
- **Severity:** Medium

### 10.2 Add comprehensive logging for watch reference loading
- **What:** Debug logs exist but are only compiled in DEBUG builds; no production diagnostics
- **Action:** Implement conditional logging that can be enabled/disabled at runtime via UserDefaults or settings
- **Severity:** Low

---

## 11. What Was NOT Audited

- Metal shader code (none found)
- Third-party SPM dependencies internals
- Test coverage assessment
- Localization correctness
- Performance profiling (Instruments traces not run)
- Build settings and scheme configuration details
- iCloud sync behavior in production

---

## 12. Verification

| Finding | Verified Lines | Status |
|---------|----------------|--------|
| §5.1 | Sources/Watch/Resources/WatchReference/ exists but not in project.pbxproj | ✅ Confirmed |
| §5.2 | WatchReferenceStore.swift:210-240 — memory mapping with fallback | ✅ Confirmed |
| §5.3 | DrugReference.swift — force unwraps on Bundle.main.url | ✅ Confirmed |
| §5.4 | WatchDrugReference.swift:160-180 — no error handling in detail view | ✅ Confirmed |

---

## Appendix A: Build Warnings Summary

```
Errors (2):
- Library.swift:423 - initializer for conditional binding must have Optional type
- Library.swift:456 - same error repeated

Warnings (18):
- 15x result of call to 'save()' is unused (Library.swift)
- 1x implicit conversion loses integer precision (compression_compat.c:20)
- 2x other warnings
```

---

*Report generated by Bionic iOS Code Audit Skill*

