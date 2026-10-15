import SwiftUI

struct EndocrinologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var fpg = "100"
    @State private var hba1c = "6.0"
    @State private var androgenAge = "45"
    @State private var testosterone = "400"
    @State private var dmSelfAge = "50"
    @State private var dmSelfGender = "Male"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "glycemic.htm":
            guard let fpg = Double(fpg), let hba = Double(hba1c), fpg >= 0, hba >= 0 else {
                return "Enter valid values"
            }
            let status = fpg >= 126 || hba >= 6.5 ? "Diabetic range (≥126 mg/dL or ≥6.5%)" :
                         fpg >= 100 || hba >= 5.7 ? "Prediabetic range (100-125 mg/dL or 5.7-6.4%)" :
                         "Normal"
            return String(format: "Fasting Glucose: %@ mg/dL\nHbA1c: %@%%\n%@  (%@)", fpg, hba1c, status, fpg >= 126 ? "Consider DM" : "Recheck in 6-12 months")
        case "androgendef.htm":
            guard let t = Double(testosterone), let a = Double(androgenAge), t >= 0, a >= 0 else {
                return "Enter valid values"
            }
            let status = t < 300 ? "Low - consider replacement" : t < 400 ? "Borderline - recheck in AM" : "Normal"
            return String(format: "Total Testosterone: %@ ng/dL (Age: %@)\n%@  (%@)", testosterone, androgenAge, status, t < 300 ? "Free T, SHBG" : "Monitor annually")
        case "dmselfassess.htm":
            let age = Int(dmSelfAge) ?? 50
            let riskFactors = age >= 45 ? 1 : 0
            let risk = riskFactors >= 2 ? "High risk - screen" : riskFactors >= 1 ? "Moderate risk" : "Low risk"
            return "DM Self-Assess: \(riskFactors)/4 risk factors"
        default: return "Not yet implemented"
        }
    }
    
    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("glycemic") || calculator.fileName.lowercased().contains("glyc") {
                Section("Glycemic Status Assessment") {
                    TextField("Fasting Plasma Glucose (mg/dL)", text: $fpg).keyboardType(.decimalPad)
                    TextField("HbA1c (%)", text: $hba1c).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("androgen") {
                Section("Androgen Deficiency Assessment") {
                    TextField("Age (years)", text: $androgenAge).keyboardType(.decimalPad)
                    TextField("Total Testosterone (ng/dL)", text: $testosterone).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("dmself") {
                Section("Diabetes Self-Assessment") {
                    TextField("Age (years)", text: $dmSelfAge).keyboardType(.decimalPad)
                    Picker("Gender", selection: $dmSelfGender) {
                        Text("Male").tag("Male"); Text("Female").tag("Female")
                    }.pickerStyle(.segmented)
                }
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
