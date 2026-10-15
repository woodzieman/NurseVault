import SwiftUI

struct OtherView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var gds1 = "1"
    @State private var gds2 = "1"
    @State private var gds3 = "1"
    @State private var gds4 = "1"
    @State private var gds5 = "1"
    @State private var gds6 = "1"
    @State private var gds7 = "1"
    @State private var gds8 = "1"
    @State private var gds9 = "1"
    @State private var gds10 = "1"
    @State private var ascNa = "130"
    @State private var ascSerumAlb = "4.0"
    @State private var ascAscitesAlb = "1.5"
    @State private var ahaAge = "60"
    @State private var ahaSbp = "130"
    @State private var ahaTch = "200"
    @State private var ahaHdl = "50"
    @State private var ahaHyp = "0"
    @State private var ahaSmoke = "0"
    @State private var ahaDM = "0"
    @State private var ahaTreatedBp = "0"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "geriatricdepression.htm":
            let total = (Int(gds1) ?? 0) + (Int(gds2) ?? 0) + (Int(gds3) ?? 0) + (Int(gds4) ?? 0)
                        + (Int(gds5) ?? 0) + (Int(gds6) ?? 0) + (Int(gds7) ?? 0) + (Int(gds8) ?? 0)
                        + (Int(gds9) ?? 0) + (Int(gds10) ?? 0)
            let risk = total >= 5 ? "Depression likely - refer" : "Unlikely"
            return String(format: "GDS-15: %d/15 (%@)", total, risk)
        case "gestationdate.htm":
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let lmpDate = formatter.date(from: "2024-01-01") ?? Date()
            let edd = Calendar.current.date(byAdding: .day, value: 280, to: lmpDate) ?? Date()
            return String(format: "LMP: %@\nEstimated Delivery: %@", formatter.string(from: lmpDate), formatter.string(from: edd))
        case "ascitesalbumingradient.htm":
            guard let na = Double(ascNa), let sa = Double(ascSerumAlb), let aa = Double(ascAscitesAlb),
                  na > 0, sa > 0, aa > 0 else { return "Enter valid values" }
            let gradient = na - (sa - aa)
            let cat = gradient >= 1.1 ? "Portal Hypertension (>95%)" : "Non-Portal (<25%)"
            return String(format: "SAAG: %.1f g/dL (%@)", gradient, cat)
        case "aha_prev2023.htm":
            guard let age = Double(ahaAge), let sbp = Double(ahaSbp), let tc = Double(ahaTch),
                  let hdl = Double(ahaHdl), age >= 20, age <= 79, sbp > 0, tc > 0, hdl > 0 else {
                return "Enter valid values (age 20-79)"
            }
            let la = log(age / 10.0), lt = log(tc), lh = log(hdl), ls = log(sbp)
            var logit = -20.46 + 3.77 * la + 0.73 * lt - 1.64 * lh + 3.43 * ls
            if ahaHyp == "1" { logit += 0.78 }
            if ahaSmoke == "1" { logit += 0.78 }
            if ahaDM == "1" { logit += 0.63 }
            if ahaTreatedBp == "1" { logit += 0.34 }
            let risk = 1.0 / (1.0 + exp(-logit)) * 100.0
            let cat = risk < 5 ? "Low Risk" : risk < 7.5 ? "Borderline" : risk < 20 ? "Intermediate" : "High Risk"
            return String(format: "10-Year ASCVD Risk: %.1f%% (%@)", risk, cat)
        default: return "Not yet implemented"
        }
    }
    
    var body: some View {
        Form {
            Section("Geriatric Depression Scale (score 0 or 1)") {
                TextField("Q1: Do you feel you have just as good health as most?", text: $gds1).keyboardType(.numberPad)
                TextField("Q2: Have you enjoyed life as much as you used to?", text: $gds2).keyboardType(.numberPad)
                TextField("Q3: Do you feel you can't get going?", text: $gds3).keyboardType(.numberPad)
                TextField("Q4: Do you do things half-way?", text: $gds4).keyboardType(.numberPad)
                TextField("Q5: Do you feel hopeless?", text: $gds5).keyboardType(.numberPad)
                TextField("Q6: Do you feel tired all the time?", text: $gds6).keyboardType(.numberPad)
                TextField("Q7: Is your appetite poor?", text: $gds7).keyboardType(.numberPad)
                TextField("Q8: Is your sleep poor?", text: $gds8).keyboardType(.numberPad)
                TextField("Q9: Do you enjoy pleasant activities?", text: $gds9).keyboardType(.numberPad)
                TextField("Q10: Do you feel like dying?", text: $gds10).keyboardType(.numberPad)
            }
            Section("Ascites Albumin Gradient (SAAG)") {
                TextField("Serum Albumin (g/dL)", text: $ascSerumAlb).keyboardType(.decimalPad)
                TextField("Ascites Albumin (g/dL)", text: $ascAscitesAlb).keyboardType(.decimalPad)
                TextField("Serum Sodium (mEq/L)", text: $ascNa).keyboardType(.decimalPad)
            }
            Section("AHA/ACC 10-Year ASCVD Risk") {
                TextField("Age (20-79)", text: $ahaAge).keyboardType(.decimalPad)
                TextField("Systolic BP (mmHg)", text: $ahaSbp).keyboardType(.decimalPad)
                TextField("Total Cholesterol (mg/dL)", text: $ahaTch).keyboardType(.decimalPad)
                TextField("HDL Cholesterol (mg/dL)", text: $ahaHdl).keyboardType(.decimalPad)
                Picker("Hypertension?", selection: $ahaHyp) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                Picker("Smoking?", selection: $ahaSmoke) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                Picker("Diabetes?", selection: $ahaDM) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
            }
            Section("Result") { Text(result) }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar { Button("Close") { dismiss() } }
    }
}
