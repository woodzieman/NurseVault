import SwiftUI

/// Lists all 174 MedCalc calculators with navigation to the detail (calculator) view.
struct CategoryListView: View {
    var body: some View {
        List {
            ForEach(MedCalcCatalog.all) { calc in
                NavigationLink {
                    CalculatorDetailView(calculator: calc)
                } label: {
                    Text(calc.title).font(.body).padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Clinical Calculators").navigationBarTitleDisplayMode(.inline)
    }
}
