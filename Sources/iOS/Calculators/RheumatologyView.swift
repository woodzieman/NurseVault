import SwiftUI

struct RheumatologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var swollenJoints = "8"
    @State private var tenderJoints = "12"
    @State private var patientGlobal = "5"
    @State private var crp = "25"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "das28.htm":
            guard let sw = Double(swollenJoints), let te = Double(tenderJoints),
                  let pg = Double(patientGlobal), let c = Double(crp),
                  sw >= 0, te >= 0, pg >= 0, c >= 0 else { return "Enter valid values (0-100%)" }
            let das28 = 0.56 * sqrt(sw) + 0.28 * sqrt(te) + 0.36 * sqrt(pg) + 0.014 * c + 0.64
            let status = das28 <= 2.6 ? "Remission" : das28 <= 3.2 ? "Low activity" : das28 <= 5.1 ? "Moderate activity" : "High activity"
            return String(format: "DAS28: %.2f (%@)", das28, status)
        case "cda.htm":
            return "See Gastroenterology CDAI"
        default: return "Not yet implemented"
        }
    }
    
    var body: some View {
        Form {
            Section("DAS28 (Rheumatoid Arthritis Activity)") {
                TextField("Swollen joint count (0-28)", text: $swollenJoints).keyboardType(.decimalPad)
                TextField("Tender joint count (0-66)", text: $tenderJoints).keyboardType(.decimalPad)
                TextField("Patient global assessment (0-100mm VAS)", text: $patientGlobal).keyboardType(.decimalPad)
                TextField("CRP (mg/L)", text: $crp).keyboardType(.decimalPad)
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle("DAS28 - Rheumatoid Arthritis")
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
