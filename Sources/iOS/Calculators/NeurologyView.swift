import SwiftUI

struct NeurologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var gcsEye = "4"
    @State private var gcsVerbal = "5"
    @State private var gcsMotor = "6"

    @State private var nihssConscious = "0"
    @State private var nihssLON = "0"
    @State private var nihssGaze = "0"
    @State private var nihssVisual = "0"
    @State private var nihssNF = "0"
    @State private var nihssAtax = "0"
    @State private var nihSSense = "0"
    @State private var nihSSpeech = "0"
    @State private var nihsSext = "0"

    @State private var csfAge = "30"
    @State private var csfWbc = "5"
    @State private var csfBd = "100"

    @State private var ibrAge = "65"
    @State private var ibrHyp = "0"
    @State private var ibrStroke = "0"
    @State private var ibrAnticoag = "0"
    @State private var ibrIcb = "0"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "glasgowcomascale.htm":
            let e = Int(gcsEye) ?? 4
            let v = Int(gcsVerbal) ?? 5
            let m = Int(gcsMotor) ?? 6
            let total = e + v + m
            let sev = total <= 8 ? "Severe (intubate)" : total <= 12 ? "Moderate" : "Mild"
            return String(format: "GCS: %d/15 (%@)", total, sev)

        case "nihsstroke.htm":
            let c = Double(nihssConscious) ?? 0
            let l = Double(nihssLON) ?? 0
            let g = Double(nihssGaze) ?? 0
            let v = Double(nihssVisual) ?? 0
            let n = Double(nihssNF) ?? 0
            let a = Double(nihssAtax) ?? 0
            let s = Double(nihSSense) ?? 0
            let p = Double(nihSSpeech) ?? 0
            let ex = Double(nihsSext) ?? 0
            let total = c + l + g + v + n + a + s + p + ex
            let sev = total <= 4 ? "Minor" : total <= 11 ? "Moderate" : total <= 20 ? "Severe" : "Maximum"
            return String(format: "NIHSS: %.0f/42 (%@)", total, sev)

        case "csfprotein.htm":
            guard let wbc = Double(csfWbc), let bd = Double(csfBd),
                  wbc > 0, bd > 0 else {
                return "Enter valid values"
            }
            let corrected = wbc + 0.5 * bd / 1000.0
            return String(format: "Corrected CSF WBC: %.0f cells/µL (corrected for blood)", corrected)

        case "intracranialbleedingrisk.htm":
            guard let age = Double(ibrAge), age > 0 else {
                return "Enter age"
            }
            var s = 0
            if age >= 65 { s += 1 }
            if ibrHyp == "1" { s += 1 }
            if ibrStroke == "1" { s += 1 }
            if ibrAnticoag == "1" { s += 1 }
            if ibrIcb == "1" { s += 1 }
            let r = s >= 3 ? "High risk" : s >= 1 ? "Moderate risk" : "Low risk"
            return String(format: "ICH Risk Score: %d/5 (%@)", s, r)

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("glasgow") {
                Section("Glasgow Coma Scale") {
                    TextField("Eye Opening (1-4)", text: $gcsEye).keyboardType(.numberPad)
                    TextField("Verbal Response (1-5)", text: $gcsVerbal).keyboardType(.numberPad)
                    TextField("Motor Response (1-6)", text: $gcsMotor).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("nihss") || calculator.fileName.lowercased().contains("nihs") {
                Section("NIH Stroke Scale") {
                    TextField("Level of Consciousness (0-2)", text: $nihssConscious).keyboardType(.numberPad)
                    TextField("Best Gaze (0-2)", text: $nihssGaze).keyboardType(.numberPad)
                    TextField("Visual (0-2)", text: $nihssVisual).keyboardType(.numberPad)
                    TextField("Facial Palsy (0-3)", text: $nihssNF).keyboardType(.numberPad)
                    TextField("Motor Arm (0-4)", text: $nihssAtax).keyboardType(.numberPad)
                    TextField("Ataxia (0-2)", text: $nihSSense).keyboardType(.numberPad)
                    TextField("Language (0-3)", text: $nihSSpeech).keyboardType(.numberPad)
                    TextField("Extinction/Aphasia (0-2)", text: $nihsSext).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("csf") {
                Section("CSF Protein Correction") {
                    TextField("Age (years)", text: $csfAge).keyboardType(.decimalPad)
                    TextField("WBC (cells/µL)", text: $csfWbc).keyboardType(.decimalPad)
                    TextField("RBC (cells/µL)", text: $csfBd).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("intracranial") || calculator.fileName.lowercased().contains("bleeding") {
                Section("Intracranial Hemorrhage Risk") {
                    TextField("Age (years)", text: $ibrAge).keyboardType(.decimalPad)
                    Picker("Hypertension", selection: $ibrHyp) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("Prior Stroke", selection: $ibrStroke) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("Anticoagulant Use", selection: $ibrAnticoag) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("Intraparenchymal Extension", selection: $ibrIcb) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            Section("Result") {
                Text(result)
            }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: result)
        .toolbar {
            Button("Close") { dismiss() }
        }
    }
}
