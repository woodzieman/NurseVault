import SwiftUI
import NurseVaultCore

/// The watch's DSM-5-TR reference: the **full** bundled disorder texts, paged
/// ~25 entries at a time with a short preview per row. Selecting a disorder
/// reads just that entry's text from the on-watch content blob (see
/// `WatchReference`), so the watch holds the whole reference without ever
/// loading it all into RAM.
struct WatchDsmReferenceView: View {
    @State private var reference = WatchReference(.dsm)
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
            placeholder: "Disorder, symptom, or ICD code",
            browseHint: "Browse or search \(reference.entries.count) disorders",
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
                if let text, !text.isEmpty {
                    results.append("✓ Successfully loaded first entry (\(text.count) chars)")
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
