import SwiftUI

struct PharmacologyAndToxicologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    // MARK: - Acetaminophen Toxicity State Properties
    @State private var acetaHours = "8"
    @State private var acetaLevelMcMolL = "300"
    
    var body: some View {
        Form {
            Section("Inputs") { contentInput }
            Section("Result") { Text(calculationResult) }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: calculationResult)
        .toolbar { Button("Close") { dismiss() } }
    }
    
    var contentInput: some View {
        Group {
            switch calculator.fileName.lowercased() {
            case "acetaminophentox2023.htm":
                acetaminophenToxInputView
            default:
                Text("Input not yet implemented")
            }
        }
    }
    
    var calculationResult: String {
        switch calculator.fileName.lowercased() {
        case "acetaminophentox2023.htm":
            return calcAcetaminophenTox()
        default:
            return "Not yet implemented"
        }
    }
    
    // MARK: - Calculation Functions
    
    func calcAcetaminophenTox() -> String {
        guard let hours = Double(acetaHours), let level = Double(acetaLevelMcMolL),
              hours >= 4 && hours <= 24, level > 0 else {
            return "Use only 4-24 hour results"
        }
        let mgPerL = level * 0.352
        if mgPerL > 200 { return "Probable toxicity - Treat with NAC" }
        if mgPerL > 50 { return "Possible toxicity - Monitor" }
        return "Low risk"
    }
    
    // MARK: - Input Views
    
    private var acetaminophenToxInputView: some View {
        VStack(spacing: 12) {
            TextField("Hours since ingestion (4-24)", text: $acetaHours).keyboardType(.decimalPad)
            TextField("Serum level (mcMol/L)", text: $acetaLevelMcMolL).keyboardType(.decimalPad)
        }
    }
}
