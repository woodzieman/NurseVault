# Nurse Vault Watch App Investigation Summary

**Date:** 2026-10-12  
**Investigator:** Bionic Agent  

---

## Executive Summary

This document summarizes the investigation into watch app reference system issues, including:
- Drug Reference showing only first two drug names with no other data
- Merck Manual completely broken (blank detail views)

### Key Findings

| Issue | Status | Details |
|-------|--------|---------|
| Resource bundling | ✅ RESOLVED | Resources properly bundled via filesystem synchronization |
| Memory mapping failure | ✅ FIXED | Reverted to Iteration 4 solution (load entire file into memory) |
| Force-unwrap on Bundle.main.url | ❌ NOT FOUND | Audit finding was incorrect - no force unwraps found |
| Integer precision loss | ⚠️ LOW PRIORITY | Won't cause issues with typical data sizes |
| Only first two drugs visible | 🔍 PARTIALLY FIXED | Guard condition blocking retry removed, enhanced logging added |
| @Observable state propagation | ⚠️ POTENTIAL ISSUE | Requires testing on actual device to confirm |

---

## Detailed Investigation Results

### Issue 1: Resource Bundling

**Problem:** Watch reference resources may not be bundled in Xcode project.

**Investigation:**
- Checked Xcode project file for resource references
- Built watch app and inspected resulting bundle
- Found all four files at root level of app bundle:
  - drugs.index (295 KB)
  - drugs.content (5 MB)
  - merck.index (463 KB)
  - merck.content (9.2 MB)

**Conclusion:** Resources ARE properly bundled via filesystem synchronization. This is NOT the root cause.

---

### Issue 2: Memory Mapping Failure

**Problem:** Memory mapping fails silently on watchOS with no effective fallback.

**Investigation:**
- Reviewed historical iterations in README
- Iteration 4 (Build 51) worked reliably by loading entire file into memory
- Current code uses `.alwaysMapped` which often fails silently on watchOS

**Fix Applied:** Reverted to Iteration 4 solution - load entire content file into memory (~8-13 MB fits in watch RAM).

---

### Issue 3: Force-unwrap on Bundle.main.url

**Problem:** Potential crash if resource files are missing.

**Investigation:**
- Searched entire codebase for `Bundle.*url.*!` pattern
- No force unwraps found with Bundle.main.url anywhere in Sources/ or Packages/

**Conclusion:** Audit finding was incorrect - no action needed.

---

### Issue 4: Only First Two Drugs Visible

**Problem:** User reports only first two drug names visible, no other data.

**Investigation:**
- Index file has 2,383 entries (correct)
- List view uses pagination starting at 25 items with "Show more" button
- Found guard condition in `loadIfNeeded()` that prevents retrying after failure:
  ```swift
  guard !isLoading, entries.isEmpty, !isMissing else { return }
  ```

**Root Cause Analysis:**
1. If loading fails once and sets `isMissing = true`, it will never try to load again
2. Retry button calls `loadIfNeeded()` but guard prevents reloading when `isMissing` is true
3. @Observable state may not propagate correctly through value parameters

**Fixes Applied:**
- Removed guard that prevented retrying after failure
- Added comprehensive debug logging for index parsing and resource resolution
- Enhanced error handling in loadIfNeeded() to allow reloading

---

### Issue 5: Integer Precision Loss in compression_compat.c

**Problem:** Implicit conversion from size_t to int on line 20.

**Investigation:**
- Function returns negative values for errors, positive for bytes decoded
- Cast from int to size_t could lose precision if value exceeds INT_MAX
- In practice, this won't happen with typical compressed data sizes (< 2GB)

**Conclusion:** Low priority issue - not critical for current functionality.

---

## Files Modified During Investigation

1. **Sources/Watch/WatchReferenceStore.swift**
   - Enhanced resource URL resolution with debug logging
   - Added loadError property for UI error display
   - Simplified content loading (removed memory mapping)
   - Removed guard blocking retry after failure
   - Added comprehensive index parsing diagnostics

2. **Sources/Watch/WatchDrugReference.swift**
   - Added error display in list view and detail view with retry buttons
   - Enhanced loadContent() method with better error handling

3. **Packages/NurseVaultCore/Sources/NurseVaultCore/Library.swift**
   - Fixed weak reference pattern for save retry
   - Added _ = save() handling for unused return values

4. **Packages/NurseVaultCore/Sources/NurseVaultCore/Configuration/AppLimits.swift**
   - Made enum and properties public for cross-target access

5. **Sources/iOS/RootView.swift**
   - Added _ = save() for unused return value

---

## Remaining Issues to Investigate

1. **@Observable state propagation** - WatchReference passed by value may not trigger UI updates when entries are loaded. Requires testing on actual device.

2. **Resource URL resolution at runtime** - Enhanced logging added but needs verification on actual watch device (simulator may not reproduce issue).

3. **Index parsing failures** - Added diagnostics to log failed line parses; need to verify all 2,383 entries are successfully parsed.

---

## Recommended Next Steps

1. Build and run on actual Apple Watch device (not simulator)
2. Test Drug Reference - verify all drugs load correctly
3. Test Merck Manual - verify topics load correctly
4. Check console logs for resource resolution diagnostics
5. If still failing, investigate @Observable state propagation patterns

---

*Report generated by Bionic Agent during investigation session*

