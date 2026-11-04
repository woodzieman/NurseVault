import SwiftUI

struct CalculatorDetailView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    // Observe the shared result store directly (Observation) instead of through a
    // NotificationCenter publisher, so toggling a favorite updates this view live.
    private let store = ResultStore.shared

    var body: some View {
        calculatorView
            .navigationTitle(calculator.title ?? "Untitled")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            Button("Close") { dismiss() }
            Button {
                store.toggleFavorite(calculator.id)
            } label: {
                Image(systemName: store.isFavorite(calculator.id) ? "star.fill" : "star")
            }
            .accessibilityLabel("Favorite")
        }
    }

    /// Routes the calculator to its implementation view by its normalized
    /// `categoryKey`, which strips punctuation and lowercases the category
    /// string. This is the single source of truth — a category mismatch in
    /// the spec file now produces a clear "not found" message instead of
    /// silently falling through to the default case.
    private var calculatorView: some View {
        switch calculator.categoryKey {
        case "cardiovascular":
            return AnyView(CardiovascularView(calculator: calculator))
        case "criticalcaresscores":
            return AnyView(CriticalCareView(calculator: calculator))
        case "ebmstatistics":
            return AnyView(EBMStatisticsView(calculator: calculator))
        case "electrolytesacidbase":
            return AnyView(ElectrolytesAcidBaseView(calculator: calculator))
        case "growthanthropometrics":
            return AnyView(GrowthAnthropometricsView(calculator: calculator))
        case "hepatic":
            return AnyView(HepaticView(calculator: calculator))
        case "pulmonary", "respiratorygasexchange":
            return AnyView(PulmonaryView(calculator: calculator))
        case "renal":
            return AnyView(RenalView(calculator: calculator))
        case "neurology":
            return AnyView(NeurologyView(calculator: calculator))
        case "neonatology":
            return AnyView(NeonatologyView(calculator: calculator))
        case "infectiousdisease":
            return AnyView(InfectiousDiseaseView(calculator: calculator))
        case "gastroenterology":
            return AnyView(GastroenterologyView(calculator: calculator))
        case "endocrinology":
            return AnyView(EndocrinologyView(calculator: calculator))
        case "oncologyandrisk":
            return AnyView(OncologyView(calculator: calculator))
        case "rheumatology":
            return AnyView(RheumatologyView(calculator: calculator))
        case "mentalhealthscreening":
            return AnyView(MentalHealthView(calculator: calculator))
        case "substanceuse":
            return AnyView(SubstanceUseView(calculator: calculator))
        case "sleepmedicine":
            return AnyView(SleepMedicineView(calculator: calculator))
        case "urology":
            return AnyView(UrologyView(calculator: calculator))
        case "unitconversions":
            return AnyView(UnitConversionsView(calculator: calculator))
        case "pediatrics":
            return AnyView(PediatricsView(calculator: calculator))
        case "hematology":
            return AnyView(HematologyView(calculator: calculator))
        case "pharmacologytoxicology":
            return AnyView(PharmacologyAndToxicologyView(calculator: calculator))
        case "obstetrics":
            return AnyView(ObstetricsView(calculator: calculator))
        default:
            return AnyView(NeverView(calculator: calculator))
        }
    }

    /// Shows a placeholder when no calculator spec matches.
    private struct NeverView: View {
        let calculator: CalculatorInfo
        var body: some View {
            ContentUnavailableView(
                "Calculator Not Found",
                systemImage: "questionmark.circle",
                description: Text("No view implementation for \(calculator.title).")
            )
        }
    }
}
