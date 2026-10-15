import SwiftUI

struct MentalHealthView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var audit1 = "0"
    @State private var audit2 = "0"
    @State private var audit3 = "0"
    @State private var audit4 = "0"
    @State private var audit5 = "0"
    @State private var audit6 = "0"
    @State private var audit7 = "0"
    @State private var audit8 = "0"
    @State private var audit9 = "0"
    @State private var audit10 = "0"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "alcoholscreen.htm":
            let total = (Int(audit1) ?? 0) + (Int(audit2) ?? 0) + (Int(audit3) ?? 0) + (Int(audit4) ?? 0) + (Int(audit5) ?? 0)
                        + (Int(audit6) ?? 0) + (Int(audit7) ?? 0) + (Int(audit8) ?? 0) + (Int(audit9) ?? 0) + (Int(audit10) ?? 0)
            let risk = total <= 7 ? "Low risk" : total <= 15 ? "Hazardous drinking" : total <= 25 ? "Harmful use" : "Severe (probable dependence)"
            return String(format: "AUDIT Score: %d/40 (%@)", total, risk)
        default: return "Not yet implemented"
        }
    }
    
    var body: some View {
        Form {
            Section("AUDIT Alcohol Screening (score each 0-4)") {
                TextField("Q1: How often do you have a drink?", text: $audit1).keyboardType(.numberPad)
                TextField("Q2: How many drinks on a typical day?", text: $audit2).keyboardType(.numberPad)
                TextField("Q3: Maximum number of drinks on one day?", text: $audit3).keyboardType(.numberPad)
                TextField("Q4: How often have you had 6 or more drinks?", text: $audit4).keyboardType(.numberPad)
                TextField("Q5: Do you find yourself unable to drink as little as you used to?", text: $audit5).keyboardType(.numberPad)
                TextField("Q6: Failed to do something because of morning drinking?", text: $audit6).keyboardType(.numberPad)
                TextField("Q7: Friends/family worried about your drinking?", text: $audit7).keyboardType(.numberPad)
                TextField("Q8: Have you had a black-out from drinking?", text: $audit8).keyboardType(.numberPad)
                TextField("Q9: Have you ever been injured as a result of alcohol?", text: $audit9).keyboardType(.numberPad)
                TextField("Q10: Does a relative/friend say you have a drinking problem?", text: $audit10).keyboardType(.numberPad)
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle("AUDIT Alcohol Screening")
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
