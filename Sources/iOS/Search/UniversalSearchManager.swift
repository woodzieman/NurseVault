import SwiftUI
import NurseVaultCore

@MainActor
@Observable
class UniversalSearchManager {
    private var searchTask: Task<Void, Never>?
    
    var searchText = "" {
        didSet {
            searchTask?.cancel()
            let query = searchText
            searchTask = Task { @MainActor in
                // Debounce 200ms
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                performSearch(query: query)
            }
        }
    }
    
    var results: [SearchResult] = []
    var isSearching = false
    /// True when the drug or Merck libraries are still loading.
    var isLoadingLibraries: Bool { drugLibrary.isLoading || merckLibrary.isLoading || dsmLibrary.isLoading }

    private let library: Library
    private let drugLibrary: DrugLibrary
    private let merckLibrary: MerckTopicLibrary
    private let dsmLibrary: DsmTopicLibrary

    init(library: Library, drugLibrary: DrugLibrary, merckLibrary: MerckTopicLibrary, dsmLibrary: DsmTopicLibrary) {
        self.library = library
        self.drugLibrary = drugLibrary
        self.merckLibrary = merckLibrary
        self.dsmLibrary = dsmLibrary
        // Ensure libraries are loaded as soon as search manager is created.
        drugLibrary.loadIfNeeded()
        merckLibrary.loadIfNeeded()
        dsmLibrary.loadIfNeeded()
    }

    private func performSearch(query rawQuery: String) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            return
        }

        isSearching = true
        
        // Search in Drug Library (Name)
        let drugHits = drugLibrary.nameHits(for: query).map { SearchResult.drug($0.entry) }
        
        // Search in Merck Topics (Name/Title)
        let topicHits = merckLibrary.nameHits(for: query).map { SearchResult.topic($0.entry) }
        
        // Search in DSM-5-TR Topics (Name/Title/Code)
        let dsmHits = dsmLibrary.nameHits(for: query).map { SearchResult.dsmTopic($0.entry) }
        
        // Search in Calculators (Title)
        let calcHits = MedCalcCatalog.all.filter { $0.title.localizedCaseInsensitiveContains(query) }.map { SearchResult.calculator($0) }
        
        // Search in User Vault Documents (Title/Content/Extracted Text)
        let docHits = library.docs.filter { doc in
            (doc.title?.localizedCaseInsensitiveContains(query) == true) ||
            (doc.noteText?.localizedCaseInsensitiveContains(query) == true) ||
            (doc.extractedText?.localizedCaseInsensitiveContains(query) == true)
        }.map { SearchResult.document($0) }
        
        results = drugHits + topicHits + dsmHits + calcHits + docHits
        isSearching = false
    }
}

