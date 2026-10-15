import SwiftUI

struct SleepMedicineView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var q1 = "0"
    @State private var q2 = "0"
    @State private var q3 = "0"
    @State private var q4 = "0"
    @State private var q5 = "0"
    @State private var q6 = "0"
    @State private var q7 = "0"
    @State private var q8 = "0"
    
    var result: String {
        let total = (Int(q1) ?? 0) + (Int(q2) ?? 0) + (Int(q3) ?? 0) + (Int(q4) ?? 0)
                  + (Int(q5) ?? 0) + (Int(q6) ?? 0) + (Int(q7) ?? 0) + (Int(q8) ?? 0)
        let risk = total <= 10 ? "Normal vigilance" : total <= 14 ? "Borderline (consider polysomnography)" : "Excessive daytime sleepiness"
        return String(format: "Epworth Sleepiness Scale: %d/24 (%@)", total, risk)
    }
    
    var body: some View {
        Form {
            Section("Epworth Sleepiness Scale (0-3 each)") {
                TextField("Sitting and reading", text: $q1).keyboardType(.numberPad)
                TextField("Watching TV", text: $q2).keyboardType(.numberPad)
                TextField("Sitting inactive in a public place", text: $q3).keyboardType(.numberPad)
                TextField("As a passenger in a car for an hour", text: $q4).keyboardType(.numberPad)
                TextField("Lying down to rest in the afternoon", text: $q5).keyboardType(.numberPad)
                TextField("Sitting and talking to someone", text: $q6).keyboardType(.numberPad)
                TextField("Sitting quietly after lunch", text: $q7).keyboardType(.numberPad)
                TextField("In a car while stopped in traffic", text: $q8).keyboardType(.numberPad)
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle("Epworth Sleepiness Scale")
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
