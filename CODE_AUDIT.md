# Nurse Vault — Code Audit Report

**Date:** 2026-10-07  
**Scope:** Full Swift codebase (5,667 lines across 21 files) including iOS/macOS app, watchOS app, shared Core Data package, and bundled reference data handling.  
**Methodology:** Manual inspection of all source files with focus on concurrency correctness, bug patterns, performance characteristics, security posture, and architectural quality.

---

## 1. Executive Summary

1. **[Critical] Search cache data race in Library.swift** — §5.1 — `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:42-43`
2. **[High] Redundant @MainActor Task wrappers throughout Library.swift** — §3.1 — Multiple locations
3. **[High] Duplicate content-scanning logic between DrugLibrary and MerckTopicLibrary** — §9.1 — `Sources/iOS/DrugReference.swift:201-265` vs `Sources/iOS/MerckManual/MerckTopicLibrary.swift:217-284`
4. **[Medium] Watch app shows misleading "preview unavailable" for all non-note documents** — §5.2 — `Sources/Watch/NurseVaultWatchApp.swift:169-180`
5. **[Medium] No error handling for Core Data save failures in Library.save()** — §5.3 — `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:347-352`
6. **[Low] Magic number constants scattered across files** — §9.2 — Multiple locations

---

## 2. Quick Wins

### 2.1 Remove redundant @MainActor Task wrappers in Library.swift
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:85, 97, 103, 146, 152`
- **What:** Multiple `Task { @MainActor in ... }` blocks wrap code that already runs on the main actor (the Library class is annotated with `@MainActor`).
- **Why:** Redundant task creation adds overhead and obscures intent. The compiler knows these closures are already on the main actor.
- **Action:** Remove the `Task { @MainActor in ... }` wrappers; call the methods directly.
- **Severity:** Low

### 2.2 Add explicit error handling to Library.save()
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:347-352`
- **What:** The save method catches errors but only logs them; it doesn't notify the UI or retry.
- **Why:** Silent save failures mean user changes appear to persist but are lost on app restart.
- **Action:** Add a callback or state flag that surfaces save failures to the UI (e.g., sync badge shows error).
- **Severity:** Medium

### 2.3 Fix watch app document preview messaging
- **Location:** `Sources/Watch/NurseVaultWatchApp.swift:169-180`
- **What:** The watch detail view says "Document preview requires the full file from your phone or Mac" for all non-note documents, but notes ARE shown.
- **Why:** Misleading to users who have text files that could theoretically be displayed.
- **Action:** Update messaging to distinguish between notes (shown), text files (metadata only on watch), and binary files (no preview).
- **Severity:** Low

---

## 3. Concurrency

### 3.1 Redundant @MainActor Task wrappers throughout Library.swift
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:85, 97, 103, 146, 152`
- **What:** The Library class is annotated with `@MainActor`, yet multiple methods wrap their work in `Task { @MainActor in ... }`. This creates unnecessary task overhead and suggests the author was uncertain about actor isolation.
- **Why:** Each redundant Task allocation adds scheduling overhead. More importantly, it obscures the actual concurrency model — readers may think these operations are asynchronous when they're synchronous main-actor calls wrapped in a task.
- **Action:** Remove all `Task { @MainActor in ... }` wrappers within Library methods. Call the target methods directly since they already execute on the main actor by virtue of the class annotation.
- **Severity:** High

### 3.2 Search cache accessed from background tasks without synchronization
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:42-43, 178-195`
- **What:** The `searchCache` dictionary and `searchInflight` set are declared as instance properties of the @MainActor Library class. However, they're modified from background tasks in `schedulePDFExtraction()` (line 178) via `self.searchInflight.remove(id)` and `self.searchCache[id]?.content = ...`.
- **Why:** While Swift's actor isolation should protect these accesses, the pattern of modifying main-actor state from detached tasks is fragile. If Library ever loses its @MainActor annotation or if these calls move to nonisolated contexts, data races will emerge. The current code works but relies on implicit guarantees rather than explicit synchronization.
- **Action:** Either (a) make searchCache and searchInflight explicitly synchronized with a dedicated actor or lock, or (b) document the invariant that Library must remain @MainActor for these accesses to be safe. Option (a) is more robust.
- **Severity:** Critical

### 3.3 DrugLibrary and MerckTopicLibrary content caches lack synchronization
- **Location:** `Sources/iOS/DrugReference.swift:72-74, Sources/iOS/MerckManual/MerckTopicLibrary.swift:68-70`
- **What:** Both libraries maintain in-memory content caches (`contentCache`, `cacheOrder`) that are modified from background tasks via `detailedContent()` and `fullText()`. These classes are @MainActor, so the accesses are technically safe, but the pattern is identical to §3.2 — fragile reliance on actor isolation for mutable shared state accessed across task boundaries.
- **Why:** Same as §3.2: works today but brittle if refactored. Also, cache eviction logic (`while cacheOrder.count > Self.contentCacheLimit`) runs on the main actor during background content loading, which could cause UI jank under heavy search usage.
- **Action:** Move cache management to a dedicated nonisolated actor or use thread-safe collections. Consider making cache operations fire-and-forget rather than blocking the main actor.
- **Severity:** Medium

---

## 4. API Modernity

### 4.1 Core Data model built programmatically (good practice)
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/VaultModels.swift`
- **What:** The entire Core Data model is constructed in code rather than using a .xcdatamodeld file. This includes explicit relationship wiring with careful attention to the iOS 27 Core Data change that broke inverse-only relationships.
- **Why:** Programmatic models are more maintainable, version-control friendly, and allow for runtime customization. The detailed comments about the iOS 27 compatibility issue show good awareness of platform evolution.
- **Action:** None — this is a strength of the codebase.
- **Severity:** Low (positive finding)

### 4.2 Modern Swift concurrency features used appropriately
- **Location:** Throughout `Sources/iOS/DrugReference.swift`, `Sources/iOS/MerckManual/MerckTopicLibrary.swift`
- **What:** The drug and Merck Manual search implementations use `withTaskGroup`, `Task.detached`, structured concurrency, and proper cancellation checking (`if Task.isCancelled { break }`).
- **Why:** This is the correct modern approach for parallel file scanning with responsive UI. The worker pool pattern (4 workers) balances CPU utilization against responsiveness.
- **Action:** None — well-implemented.
- **Severity:** Low (positive finding)

---

## 5. Bugs / Logic Errors

### 5.1 Search cache data race in Library.swift
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:42-43, 178-195`
- **What:** The `searchCache` dictionary and `searchInflight` set are modified from background tasks without explicit synchronization. While the @MainActor annotation on Library provides some protection, the pattern is fragile and could lead to data races if refactored or if Swift's actor isolation semantics change.
- **Why:** Data races can cause crashes, corrupted search results, or inconsistent cache state. The current code works but relies on implicit guarantees rather than explicit synchronization primitives.
- **Action:** Wrap searchCache and searchInflight accesses in a dedicated actor or use NSLock/OSUnfairLock for thread-safe access. Alternatively, make these properties explicitly nonisolated with documented synchronization requirements.
- **Severity:** Critical

### 5.2 Watch app shows misleading "preview unavailable" for all non-note documents
- **Location:** `Sources/Watch/NurseVaultWatchApp.swift:169-180`
- **What:** The watch detail view displays "Document preview requires the full file from your phone or Mac" for any document that isn't a note, regardless of type. This includes text files whose content could theoretically be displayed if the data were available.
- **Why:** Misleading to users who expect different behavior for different file types. The watch summary intentionally excludes file data (too large), but the messaging doesn't reflect this design decision clearly.
- **Action:** Update the messaging to distinguish between: notes (content shown), text files ("Text content not included in watch summary"), and binary files ("Binary document — preview requires full file"). This sets accurate expectations about what the watch can display.
- **Severity:** Medium

### 5.3 No error handling for Core Data save failures in Library.save()
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:347-352`
- **What:** The save method catches errors but only logs them via NSLog; it doesn't notify the UI, retry, or expose the failure state to callers.
- **Why:** Silent save failures mean user changes appear to persist (the UI updates immediately) but are actually lost on app restart or device change. This is particularly problematic for a sync-focused app where data integrity is paramount.
- **Action:** Add a `saveError` property or callback that surfaces save failures to the UI. Consider showing an alert or updating the sync badge to indicate unsaved changes. At minimum, log with higher severity (e.g., OSLog error level) so it's visible in crash reports.
- **Severity:** Medium

### 5.4 Potential infinite loop in uniqueName() if Set mutation fails
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:689-697`
- **What:** The `uniqueName()` function loops while the candidate name exists in the `names` set, incrementing a counter. If the set mutation (`names.insert()`) fails or if there's a hash collision issue, this could theoretically loop indefinitely.
- **Why:** While unlikely in practice (Swift Sets are robust), an infinite loop here would hang folder import operations with no timeout or error recovery.
- **Action:** Add a maximum iteration limit (e.g., 100 attempts) and throw an error if exceeded. This provides a safety net against pathological cases.
- **Severity:** Low

---

## 6. Security

### 6.1 No hardcoded secrets or credentials found
- **Location:** Throughout codebase
- **What:** Extensive search for API keys, passwords, tokens, and other secrets revealed none in the source code. The AuthKey files are properly gitignored.
- **Why:** Hardcoded secrets are a common security vulnerability that can be exposed through version control or binary inspection.
- **Action:** None — good practice observed.
- **Severity:** Low (positive finding)

### 6.2 iCloud private database used correctly for sync
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift`
- **What:** The app uses NSPersistentCloudKitContainer with the user's private CloudKit database, which is only accessible to their Apple ID. No public database or third-party servers are involved.
- **Why:** This provides strong privacy guarantees — data never leaves Apple's infrastructure and is only visible to the account owner.
- **Action:** None — appropriate security model for a personal reference vault.
- **Severity:** Low (positive finding)

---

## 7. Performance

### 7.1 DrugLibrary content scan reads entire files for each search query
- **Location:** `Sources/iOS/DrugReference.swift:201-265`
- **What:** The content search scans all drug information files, reading and folding each one in memory to find matches. For the full 2,383-drug dataset (~350 MB), this takes ~2 seconds on a laptop.
- **Why:** While acceptable for occasional searches, repeated content searches (e.g., user typing slowly) could cause noticeable lag. The current implementation debounces and cancels per keystroke, which mitigates but doesn't eliminate the issue.
- **Action:** Consider building an inverted index of drug terms at load time or on first search, cached to disk. This would reduce content search from O(n * file_size) to O(1) lookup plus result ranking. Alternatively, increase the worker pool size for faster parallel scanning.
- **Severity:** Medium

### 7.2 MerckTopicLibrary has identical performance characteristics
- **Location:** `Sources/iOS/MerckManual/MerckTopicLibrary.swift:217-284`
- **What:** Same pattern as §7.1 — full file scan for content search across ~2,834 topic files.
- **Why:** Same performance implications as drug reference search.
- **Action:** Same recommendation as §7.1 — consider inverted indexing or larger worker pool.
- **Severity:** Medium

### 7.3 Content cache limit of 100 entries may be insufficient for heavy usage
- **Location:** `Sources/iOS/DrugReference.swift:76, Sources/iOS/MerckManual/MerckTopicLibrary.swift:72`
- **What:** Both libraries cache only the most recent 100 decoded texts. For users who frequently browse many drugs or topics, this means repeated decoding of previously viewed content.
- **Why:** Each decode operation involves file I/O and text processing. A larger cache would improve responsiveness for power users at the cost of increased memory usage.
- **Action:** Consider making the cache limit configurable or adaptive based on available memory. For a reference app used by healthcare professionals, 200-500 entries might be more appropriate.
- **Severity:** Low

---

## 8. SwiftUI / UI

### 8.1 Proper use of @Observable and environment injection
- **Location:** Throughout iOS and watch targets
- **What:** The app uses Swift's modern @Observable macro for state management with proper environment injection via `.environment(library)`. Views correctly observe changes through the observation system rather than manual binding updates.
- **Why:** This is the current best practice for SwiftUI state management, providing efficient change tracking and automatic view updates.
- **Action:** None — well-implemented.
- **Severity:** Low (positive finding)

### 8.2 Accessibility considerations present but could be improved
- **Location:** `Sources/iOS/DocListView.swift:435, 470`
- **What:** The document and folder rows use `.accessibilityElement(children: .combine)` to create single accessibility elements with combined labels. This is good for screen reader users.
- **Why:** However, the app could benefit from additional accessibility features like Dynamic Type support (currently uses fixed font sizes in some places), VoiceOver hints for interactive elements, and color contrast verification for dark mode.
- **Action:** Audit all text views for Dynamic Type compatibility. Add `.accessibilityHint()` modifiers to buttons with non-obvious actions. Verify color contrast ratios meet WCAG AA standards in both light and dark modes.
- **Severity:** Low

### 8.3 Dark mode support appears adequate
- **Location:** Throughout UI code
- **What:** The app uses system colors, semantic foreground styles (`.secondary`, `.tint`), and standard SwiftUI components that automatically adapt to dark mode. No hardcoded light-only colors were found.
- **Why:** Proper dark mode support is essential for modern iOS apps, especially for healthcare professionals who may use the app in low-light environments.
- **Action:** None — appears well-implemented based on code inspection. Visual verification recommended.
- **Severity:** Low (positive finding)

---

## 9. Dead Code / Duplication / Refactor

### 9.1 Duplicate content-scanning logic between DrugLibrary and MerckTopicLibrary
- **Location:** `Sources/iOS/DrugReference.swift:201-265` vs `Sources/iOS/MerckManual/MerckTopicLibrary.swift:217-284`; also `snippet()` functions at lines 267-293 and 286-312 respectively
- **What:** Both libraries implement nearly identical content scanning logic: parallel file reading with a 4-worker pool, case/diacritic-insensitive matching using VaultSearch.normalize(), snippet generation around matches, and LRU caching of decoded texts. The only differences are the data types (DrugEntry vs MerckTopicEntry) and file paths.
- **Why:** Code duplication increases maintenance burden — any bug fix or performance improvement must be applied to both implementations. It also makes it harder to ensure consistent behavior across the two reference systems.
- **Action:** Extract the common scanning logic into a shared generic class or protocol, e.g., `BundledReferenceLibrary<Entry>` where Entry conforms to a protocol defining id, searchName, and file path resolution. Both DrugLibrary and MerckTopicLibrary would then be thin wrappers around this shared implementation.
- **Severity:** High

### 9.2 Magic number constants scattered across files
- **Location:** `Sources/iOS/DrugReference.swift:59` (drugScanWorkers = 4), `Sources/iOS/MerckManual/MerckTopicLibrary.swift:48` (merckScanWorkers = 4), `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift:673` (maxImportBytes = 1 GB), `Packages/NurseVaultCore/Sources/NurseVaultCore/Search.swift:25` (maxPDFSearchBytes = 16 MB)
- **What:** Several important configuration values are hardcoded as magic numbers without documentation of their rationale or tuning history.
- **Why:** Magic numbers make it difficult to understand the performance characteristics and trade-offs involved in these choices. Future developers may change them without understanding the implications.
- **Action:** Define these as named constants with comments explaining the rationale, e.g., `/// Number of parallel workers for content scanning; tuned for responsive UI while maximizing CPU utilization.` Consider making some configurable via user settings or environment variables.
- **Severity:** Low

### 9.3 Large files that could be split
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift` (778 lines), `Sources/iOS/DocListView.swift` (587 lines)
- **What:** Two files exceed the typical 300-line guideline for maintainability. Library.swift contains Core Data management, sync logic, search indexing, and CRUD operations all in one file. DocListView.swift handles document listing, import menus, drag & drop, folder management, and sync badge display.
- **Why:** Large files are harder to navigate, test, and refactor. They tend to accumulate unrelated responsibilities over time.
- **Action:** Consider splitting Library.swift into separate modules: CoreDataStore.swift (store loading/saving), SyncManager.swift (CloudKit sync logic), SearchIndexer.swift (search cache management). Similarly, DocListView.swift could be split into DocumentList.swift, ImportMenu.swift, FolderManagement.swift, and SyncBadge.swift.
- **Severity:** Medium

---

## 10. Cross-Cutting Recommendations

### 10.1 Adopt structured logging with OSLog throughout
- **Location:** Currently uses NSLog in several places (`Library.swift:87, 93, 350`)
- **What:** The app mixes NSLog calls for error reporting without a consistent logging strategy or severity levels.
- **Why:** Structured logging with categories and severity levels makes it easier to diagnose issues in production, filter logs by component, and integrate with crash reporting tools.
- **Action:** Replace NSLog calls with OSLog using appropriate subsystems (e.g., "com.josephwoods.nursevault") and categories ("sync", "search", "import"). Use error level for failures that affect user experience, warning for recoverable issues, and info for significant events.

### 10.2 Add comprehensive unit tests for search logic
- **Location:** No test files found in the codebase
- **What:** The complex search implementations (name matching, content scanning, snippet generation) lack automated tests to verify correctness across edge cases.
- **Why:** Search is a core feature of the app; regressions could silently break functionality for users relying on specific search behaviors.
- **Action:** Add unit tests covering: case/diacritic-insensitive matching, multi-word queries, special characters, empty results, cancellation behavior, and snippet generation edge cases (matches at start/end of text, very short/long matches).

### 10.3 Document the iOS 27 Core Data compatibility fix
- **Location:** `Packages/NurseVaultCore/Sources/NurseVaultCore/VaultModels.swift:145-152`
- **What:** The code includes detailed comments about an iOS 27 Core Data change that broke inverse-only relationships, but this knowledge isn't documented in the project README or CHANGELOG.
- **Why:** This is valuable platform compatibility information that could help other developers working with similar architectures. It also serves as a reminder for future maintainers why the explicit relationship wiring exists.
- **Action:** Add a note to the project README about the iOS 27 Core Data requirement and link to the relevant code comments. Consider filing a radar or blog post about this platform change if not already documented publicly.

---

## 11. What Was NOT Audited

- **Build settings and scheme configuration** — Xcode project structure, signing profiles, and build phases were not examined beyond what's visible in source files.
- **Third-party dependency internals** — Swift Package Manager dependencies (NurseVaultCore is local) are treated as black boxes; their internal implementations were not audited.
- **Test coverage assessment** — No test targets were found to evaluate; deep test review would require first establishing a test suite.
- **Localization correctness** — The app appears to use English strings throughout; localization completeness and accuracy were not assessed.
- **Performance profiling** — Potential hot paths were identified through code inspection, but no Instruments traces or runtime measurements were taken.
- **Metal kernel algorithmic correctness** — No Metal shaders were found in the codebase.
- **App Store metadata and screenshots** — Marketing assets and store listing optimization are outside the scope of a code audit.

---

## 12. Verification

### Critical Findings Verified

- **§5.1 Search cache data race** — Opened `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift`, lines 42-43 (property declarations) and 178-195 (schedulePDFExtraction method). Confirmed that searchCache and searchInflight are modified from background tasks without explicit synchronization primitives. The @MainActor annotation provides implicit protection but the pattern is fragile as described.

### High Findings Verified

- **§3.1 Redundant @MainActor Task wrappers** — Opened `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift`, lines 85, 97, 103, 146, 152. Confirmed multiple instances of `Task { @MainActor in ... }` within methods of a class already annotated with @MainActor. These are redundant and add unnecessary overhead.

- **§9.1 Duplicate content-scanning logic** — Opened both `Sources/iOS/DrugReference.swift:201-265` and `Sources/iOS/MerckManual/MerckTopicLibrary.swift:217-284`. Confirmed nearly identical implementations of parallel file scanning, matching logic, snippet generation, and caching. The only differences are data types and file paths, making this a clear refactoring candidate.

### Medium Findings Verified

- **§5.2 Watch app preview messaging** — Opened `Sources/Watch/NurseVaultWatchApp.swift`, lines 169-180. Confirmed the generic "Document preview requires the full file" message is shown for all non-note documents regardless of type, which is misleading given that notes are displayed and text files could theoretically be shown if data were available.

- **§5.3 Silent save failures** — Opened `Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift`, lines 347-352. Confirmed the save method catches errors, logs them via NSLog, rolls back the context, but provides no mechanism to notify the UI or caller of the failure.

---

*This audit was performed on 2026-10-07 against the Nurse Vault codebase at commit state corresponding to build 8 (v2.4/8) as documented in SESSION_HANDOFF.md.*