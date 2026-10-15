import SwiftUI

struct OncologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var age = "50"
    @State private var firstPeriod = "13"
    @State private var firstBirth = "28"
    @State private var breastCancerRelatives = "0"
    @State private var benignBiopsy = "0"
    @State private var ecogLevel="0"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "gail.htm", "gail2018.htm":
            guard let a = Double(age), let fp = Double(firstPeriod), let fb = Double(firstBirth),
                  a >= 0, fp >= 0, fb >= 0 else { return "Enter valid values" }
            let yearsSinceMenopause = max(0.0, a - fp)
            let relatives = Double(breastCancerRelatives) ?? 0
            let biopsy = Double(benignBiopsy) ?? 0
            let riskFactor = 1.0 + relatives * 0.1 + biopsy * 0.05
            let baseRisk = a < 50 ? 0.05 : a < 60 ? 0.10 : a < 70 ? 0.15 : 0.20
            let risk = baseRisk * riskFactor * pow(1.1, yearsSinceMenopause / 10.0)
            var interpretation: String
            if risk < 0.017 {
                interpretation = "Below average risk"
            } else if risk < 0.03 {
                interpretation = "Average risk"
            } else if risk < 0.05 {
                interpretation = "Above average risk"
            } else {
                interpretation = "High risk - consider genetic testing"
            }
            return String(format: "Gail Model: %.1f%% 5-yr / %.1f%% Lifetime\n%@ (Consider mammography/ultrasound)",
                          risk * 10, risk * 20, interpretation)
        case "ecog.htm":
            let level = Int(ecogLevel) ?? 0
            let status = level == 0 ? "Fully active" : level == 1 ? "Restrictively physically ambulatory" :
                         level == 2 ? "Ambulatory >12h/day" : level == 3 ? "Capable of limited self-care" : "Completely disabled"
            return "ECOG: \(level)/4 - \(status)"
        case "magig.htm":
            return "MAGGIC Heart Failure: requires full input set"
        default: return "Not yet implemented"
        }
    }
    
    var body: some View {
        Form {
            Section("Gail Model (Breast Cancer Risk)") {
                TextField("Current Age (years)", text: $age).keyboardType(.decimalPad)
                TextField("Age at First Period (years)", text: $firstPeriod).keyboardType(.decimalPad)
                TextField("Age at First Live Birth (years, 99 if none)", text: $firstBirth).keyboardType(.decimalPad)
                TextField("Number of First-Degree Relatives with Breast Cancer", text: $breastCancerRelatives).keyboardType(.numberPad)
                TextField("Number of Benign Biopsies (0-4)", text: $benignBiopsy).keyboardType(.numberPad)
            }
            if calculator.fileName.lowercased().contains("ecog") {
                Section("ECOG Performance Status") {
                    Picker("Level", selection: $ecogLevel) {
                        Text("0 - Fully active").tag("0")
                        Text("1 - Restrictive").tag("1")
                        Text("2 - Ambulatory >12h").tag("2")
                        Text("3 - Limited self-care").tag("3")
                        Text("4 - Completely disabled").tag("4")
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
