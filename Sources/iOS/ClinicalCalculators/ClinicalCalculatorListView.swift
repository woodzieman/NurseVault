import SwiftUI

public struct ClinicalCalculatorListView: View {
    @State private var catalog = ClinicalCalculatorCatalog.shared
    
    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if catalog.isLoading {
                    ProgressView()
                } else if let error = catalog.error {
                    VStack {
                        Text("Error loading calculators")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                    }
                } else {
                    List(catalog.calculators) { calculator in
                        NavigationLink(destination: ClinicalCalculatorDetailView(calculator: calculator)) {
                            Text(calculator.title)
                        }
                    }
                }
            }
            .navigationTitle("Clinical Calculators")
            .onAppear {
                catalog.load()
            }
        }
    }
}

struct ClinicalCalculatorDetailView: View {
    let calculator: ClinicalCalculator
    
    var body: some View {
        ClinicalCalculatorWebView(fileName: calculator.fileName)
            .navigationTitle(calculator.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
