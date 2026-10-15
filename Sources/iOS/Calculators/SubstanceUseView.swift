import SwiftUI

struct SubstanceUseView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var nausea = "0"
    @State private var tremor = "0"
    @State private var paraesthesia = "0"
    @State private var sweating = "0"
    @State private var anxiety = "0"
    @State private var agitation = "0"
    @State private var hallucTactile = "0"
    @State private var hallucVisual = "0"
    @State private var hallucAuditory = "0"
    @State private var headache = "0"
    @State private var temp = "0"
    @State private var tempSeizure = "0"
    
    var result: String {
        let total = (Int(nausea) ?? 0) + (Int(tremor) ?? 0) + (Int(paraesthesia) ?? 0) + (Int(sweating) ?? 0)
                  + (Int(anxiety) ?? 0) + (Int(agitation) ?? 0) + (Int(hallucTactile) ?? 0) + (Int(hallucVisual) ?? 0)
                  + (Int(hallucAuditory) ?? 0) + (Int(headache) ?? 0) + (Int(temp) ?? 0) + (Int(tempSeizure) ?? 0)
        let severity = total < 10 ? "Mild (8-15)" : total < 20 ? "Moderate (15-30)" : total < 40 ? "Severe (30-45)" : "Very Severe (>45)"
        return String(format: "CIWA-Ar Score: %d/152 (%@)", total, severity)
    }
    
    var body: some View {
        Form {
            Section("CIWA-Ar Alcohol Withdrawal (score each 0-7)") {
                TextField("Nausea/vomiting", text: $nausea).keyboardType(.numberPad)
                TextField("Tremor", text: $tremor).keyboardType(.numberPad)
                TextField("Paraesthesia (touch/hallucinations)", text: $paraesthesia).keyboardType(.numberPad)
                TextField("Sweating", text: $sweating).keyboardType(.numberPad)
                TextField("Anxiety", text: $anxiety).keyboardType(.numberPad)
                TextField("Agitation", text: $agitation).keyboardType(.numberPad)
                TextField("Tactile hallucinations", text: $hallucTactile).keyboardType(.numberPad)
                TextField("Visual hallucinations", text: $hallucVisual).keyboardType(.numberPad)
                TextField("Auditory hallucinations", text: $hallucAuditory).keyboardType(.numberPad)
                TextField("Headache/fullness", text: $headache).keyboardType(.numberPad)
                TextField("Temperature elevation", text: $temp).keyboardType(.numberPad)
                TextField("Seizure (0 or 10)", text: $tempSeizure).keyboardType(.numberPad)
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle("CIWA-Ar Alcohol Withdrawal")
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
