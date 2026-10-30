import SwiftUI

struct UniversalSearchResultsView: View {
    let results: [SearchResult]
    let isLoadingLibraries: Bool
    let onSelect: (SearchResult) -> Void

    var body: some View {
        List {
            if isLoadingLibraries && results.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading references...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term.")
                )
            } else {
                ForEach(results) { result in
                    Button {
                        onSelect(result)
                    } label: {
                        SearchResultRow(result: result)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Search Results")
    }
}

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 12) {
            icon
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var icon: some View {
        switch result {
        case .drug: return Image(systemName: "pills")
        case .topic: return Image(systemName: "book")
        case .dsmTopic: return Image(systemName: "cross.case")
        case .calculator: return Image(systemName: "calculator")
        case .document: return Image(systemName: "doc.text")
        }
    }

    private var title: String {
        switch result {
        case .drug(let entry): return entry.drugName
        case .topic(let topic): return topic.title
        case .dsmTopic(let entry): return entry.title
        case .calculator(let calc): return calc.title
        case .document(let doc): return doc.title ?? "Untitled"
        }
    }

    private var category: String {
        switch result {
        case .drug: return "Drug Reference"
        case .topic: return "Merck Manual"
        case .dsmTopic: return "DSM-5-TR"
        case .calculator(let calc): return "Calculator: \(calc.category)"
        case .document: return "Vault Document"
        }
    }
}
