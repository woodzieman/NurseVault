import SwiftUI

struct CalculatorDetailView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var isFavorite = false

    var body: some View {
        Group {
            switch calculator.category.lowercased() {
            case "cardiovascular":
                CardiovascularView(calculator: calculator)
            case "critical care scores":
                CriticalCareView(calculator: calculator)
            case "ebm & statistics":
                EBMStatisticsView(calculator: calculator)
            case "electrolytes & acid-base":
                ElectrolytesAcidBaseView(calculator: calculator)
            case "growth & anthropometrics":
                GrowthAnthropometricsView(calculator: calculator)
            case "hepatic":
                HepaticView(calculator: calculator)
            case "pulmonary", "respiratory & gas exchange":
                PulmonaryView(calculator: calculator)
            case "renal":
                RenalView(calculator: calculator)
            case "neurology":
                NeurologyView(calculator: calculator)
            case "neonatology":
                NeonatologyView(calculator: calculator)
            case "infectious disease":
                InfectiousDiseaseView(calculator: calculator)
            case "gastroenterology":
                GastroenterologyView(calculator: calculator)
            case "endocrinology":
                EndocrinologyView(calculator: calculator)
            case "oncology & risk":
                OncologyView(calculator: calculator)
            case "rheumatology":
                RheumatologyView(calculator: calculator)
            case "mental health & screening":
                MentalHealthView(calculator: calculator)
            case "substance use":
                SubstanceUseView(calculator: calculator)
            case "sleep medicine":
                SleepMedicineView(calculator: calculator)
            case "urology":
                UrologyView(calculator: calculator)
            case "unit conversions":
                UnitConversionsView(calculator: calculator)
            case "pediatrics":
                PediatricsView(calculator: calculator)
            case "hematology":
                HematologyView(calculator: calculator)
            case "pharmacology & toxicology":
                PharmacologyAndToxicologyView(calculator: calculator)
            case "obstetrics":
                ObstetricsView(calculator: calculator)
            case "other":
                OtherView(calculator: calculator)
            default:
                Text("Calculator view not yet implemented: \(calculator.title)")
            }
        }
        .navigationTitle(calculator.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            Button("Close") { dismiss() }
            Button {
                ResultStore.shared.toggleFavorite(calculator.id)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
            .accessibilityLabel("Favorite")
        }
        .onAppear { refreshFavoriteState() }
        .onReceive(NotificationCenter.default.publisher(for: ResultStore.didChange)) { _ in
            refreshFavoriteState()
        }
    }

    private func refreshFavoriteState() {
        isFavorite = ResultStore.shared.isFavorite(calculator.id)
    }
}
