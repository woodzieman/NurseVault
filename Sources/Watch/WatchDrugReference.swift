import SwiftUI
import NurseVaultCore

/// The watch's Drug Reference: the **full** bundled prescribing data, paged
/// ~25 rows at a time with a short preview per row. Selecting a drug reads
/// just that drug's text from the on-watch content blob (see
/// `WatchReference`), so the watch holds the whole reference without ever
/// loading it all into RAM.
struct WatchDrugReferenceView: View {
    @State private var reference = WatchReference(.drugs)
    @State private var searchText = ""
    @State private var query = ""
    @State private var visibleCount = 25
    
    /// Diagnostic state for testing resource access
    @State private var diagnosticResult: String? = nil
    @State private var showDiagnosticAlert = false

    private var all: [WatchReferenceEntry] {
        query.isEmpty ? reference.entries : reference.search(query)
    }

    var body: some View {
        WatchReferenceListView(
            reference: reference,
            placeholder: "Drug name, brand, or class",
            browseHint: "Browse or search \(reference.entries.count) drugs",
            searchText: $searchText,
            all: all,
            visibleCount: $visibleCount
        )
        .navigationTitle(reference.name.label)
        .toolbar {
            #if DEBUG
            Button(action: { runDiagnostics() }) {
                Label("Diagnose", systemImage: "wrench.and.screwdriver")
            }
            #endif
        }
        .alert(diagnosticResult ?? "", isPresented: $showDiagnosticAlert) {
            Button("OK", role: .cancel) { diagnosticResult = nil }
        }
        .navigationDestination(for: WatchReferenceEntry.self) { entry in
            WatchReferenceDetailView(reference: reference, entry: entry)
        }
        .task { reference.loadIfNeeded() }
        .onChange(of: searchText) { _, newValue in
            // Short debounce keeps the crown/typing responsive without
            // re-filtering on every intermediate keystroke.
            let text = newValue
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                if !Task.isCancelled && searchText == text {
                    query = text
                    visibleCount = 25
                }
            }
        }
    }
    
    /// Run diagnostics to test resource access and decompression
    private func runDiagnostics() {
        Task {
            var results: [String] = []
            
            // Test 1: Check if index file exists
            let indexPath = reference.name.rawValue + ".index"
            if Bundle.main.url(forResource: indexPath, withExtension: nil) != nil {
                results.append("✓ Index file found")
            } else {
                results.append("✗ Index file NOT found")
            }
            
            // Test 2: Check if content file exists
            let contentPath = reference.name.rawValue + ".content"
            if Bundle.main.url(forResource: contentPath, withExtension: nil) != nil {
                results.append("✓ Content file found")
            } else {
                results.append("✗ Content file NOT found")
            }
            
            // Test 3: Try to load first entry
            if !reference.entries.isEmpty {
                let firstEntry = reference.entries[0]
                let text = await reference.text(for: firstEntry)
                if text != nil {
                    results.append("✓ Successfully loaded first entry (\(text!.count) chars)")
                } else {
                    results.append("✗ Failed to load first entry: \(firstEntry.title)")
                    if let error = reference.loadError {
                        results.append("  Error: \(error)")
                    }
                }
            }
            
            diagnosticResult = "Diagnostics:\n" + results.joined(separator: "\n")
            showDiagnosticAlert = true
        }
    }
}

/// Shared paged list for a `WatchReference` dataset: search field, ~25 rows
/// (growable via "Show more"), title + preview per row.
struct WatchReferenceListView: View {
    let reference: WatchReference
    let placeholder: String
    let browseHint: String
    @Binding var searchText: String
    let all: [WatchReferenceEntry]
    @Binding var visibleCount: Int

    private static let pageSize = 25

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        List {
            Section {
                TextField(placeholder, text: $searchText)
                    .autocorrectionDisabled()
            }

            // Show error state if loading failed
            if let error = reference.loadError {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(
                            "Reference data unavailable",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Button(action: {
                            reference.loadIfNeeded()
                        }) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                }
            } else if reference.isMissing {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(
                            "Reference data not available",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Text("Please reinstall the app or contact support.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else if all.isEmpty {
                Section {
                    if isSearching {
                        Text("No matches for “\(searchText)”.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if reference.isLoading {
                        ProgressView()
                    } else {
                        Text(browseHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    ForEach(all.prefix(visibleCount)) { entry in
                        NavigationLink(value: entry) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.footnote)
                                if !entry.preview.isEmpty {
                                    Text(entry.preview)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    if all.count > visibleCount {
                        Button {
                            visibleCount += Self.pageSize
                        } label: {
                            Text("Show \(min(Self.pageSize, all.count - visibleCount)) more")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

/// The full text of one reference entry: seek + read + inflate of that entry
/// only, rendered scrollable on the watch.
struct WatchReferenceDetailView: View {
    let reference: WatchReference
    let entry: WatchReferenceEntry

    @State private var text: String?
    @State private var isLoading = true
    @State private var loadError: String? = nil
    
    /// Track if we've attempted to load content yet (for retry logic)
    @State private var hasAttemptedLoad = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !entry.extra.isEmpty {
                    Text(entry.extra)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Show error state
                if let error = loadError {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Failed to load content")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: {
                            // Reset and retry
                            hasAttemptedLoad = false
                            loadContent()
                        }) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                } else if let text {
                    let body = Self.bodyText(for: text)
                    // Watch has limited memory; truncate very long entries
                    // to the first ~8KB (roughly 2-3 screens of scrolling).
                    let displayText = body.count > 8000 ? String(body.prefix(8000)) + "\n\n…" : body
                    Text(displayText)
                        .font(.footnote)
                } else if isLoading {
                    ProgressView("Loading…")
                        .padding()
                } else if !hasAttemptedLoad {
                    // Reference not loaded yet - wait for it
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Preparing…")
                            .font(.headline)
                        Text("Loading reference data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    // Unknown error state
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Content unavailable")
                            .font(.headline)
                        Button(action: { loadContent() }) {
                            Label("Try again", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle(entry.title)
        .task {
            // Wait for reference to be loaded before attempting content load
            // Poll with increasing delays up to 5 seconds max wait time
            var attempts = 0
            while (reference.isLoading || reference.isMissing) && attempts < 10 {
                try? await Task.sleep(for: .milliseconds(200))
                if Task.isCancelled { return }
                attempts += 1
            }
            
            // If still loading after waiting, proceed anyway to show error state
            loadContent()
        }
    }
    
    private func loadContent() {
        hasAttemptedLoad = true
        isLoading = true
        loadError = nil
        text = nil
        
        #if DEBUG
        NSLog("NurseVault (watch): Loading detail for '\(entry.title)' at offset \(entry.contentStart)-\(entry.contentEnd)")
        #endif
        
        Task {
            // Check if reference is ready
            if reference.isMissing {
                loadError = "Reference data not available. Please reinstall the app."
                isLoading = false
                return
            }
            
            if let error = reference.loadError {
                loadError = error
                isLoading = false
                return
            }
            
            // Load content with timeout protection
            let deadline = Date.now.addingTimeInterval(30)
            text = await reference.text(for: entry)
            
            if Date.now > deadline {
                loadError = "Loading timed out. Please try again."
                #if DEBUG
                NSLog("NurseVault (watch): Timeout loading content for '\(entry.title)'")
                #endif
            }
            
            if let t = text {
                #if DEBUG
                NSLog("NurseVault (watch): Loaded \(t.count) chars for '\(entry.title)'")
                #endif
            } else {
                // Check reference error first, then provide helpful default message
                loadError = reference.loadError ?? "Failed to load content. Please try again or reinstall the app."
                #if DEBUG
                NSLog("NurseVault (watch): FAILED to load text for '\(entry.title)' - \(loadError ?? "unknown error")")
                #endif
            }
            isLoading = false
        }
    }

    /// Drops the leading metadata header (`===` / `Source:` / `Retrieved:` /
    /// `Section:` lines) so the article starts at real content. Everything
    /// else — including the nursing quick-reference summary block — stays.
    private static func bodyText(for text: String) -> String {
        let headerPrefixes = ["===", "Section:", "Source:", "Retrieved:"]
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || headerPrefixes.contains(where: trimmed.hasPrefix) {
                index += 1
                continue
            }
            break
        }
        return lines.dropFirst(index).joined(separator: "\n")
    }
}
