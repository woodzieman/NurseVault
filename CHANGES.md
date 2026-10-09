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
