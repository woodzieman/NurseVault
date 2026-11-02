import SwiftUI

/// Lists all 174 MedCalc calculators with navigation to the detail
/// (calculator) view, and a search field to filter name or category.
struct CategoryListView: View {
    /// A calculator chosen from the universal search (or a deep link). The
    /// list filters to it when the view appears; the push onto the stack is
    /// driven by RootView, which owns the NavigationStack.
    var initialCalculator: CalculatorInfo? = nil

    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(visibleCalculators) { calc in
                NavigationLink(value: calc) {
                    Text(calc.title).font(.body).padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Name or category")
        .navigationTitle("Clinical Calculators")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if let calc = initialCalculator {
                // Filter the list to the chosen calculator, so going back
                // lands on a short, relevant list (matches the drug flow).
                searchText = calc.title
            }
        }
    }

    private var visibleCalculators: [CalculatorInfo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return MedCalcCatalog.all }
        return MedCalcCatalog.all.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.category.localizedCaseInsensitiveContains(query)
        }
    }
}
