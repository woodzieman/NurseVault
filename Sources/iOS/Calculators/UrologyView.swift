import SwiftUI

struct UrologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var voidedVolume = "500"
    @State private var prostateVolume = "30"
    
    var result: String {
        guard let v = Double(voidedVolume), let p = Double(prostateVolume), v > 0, p > 0 else {
            return "Enter valid values"
        }
        let ratio = v / p
        let severity = ratio < 20 ? "Low likelihood of obstruction" : ratio < 50 ? "Possible obstruction" : "High likelihood of obstruction"
        return String(format: "V/P Ratio: %.1f mL (Voided/Prostate Vol)\n%@ (Consider urodynamics if >20)", ratio, severity)
    }
    
    var body: some View {
        Form {
            Section("Prostatism Assessment") {
                TextField("Voided Volume (mL)", text: $voidedVolume).keyboardType(.decimalPad)
                TextField("Prostate Volume (mL, from ultrasound)", text: $prostateVolume).keyboardType(.decimalPad)
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle("Prostatism Score")
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
