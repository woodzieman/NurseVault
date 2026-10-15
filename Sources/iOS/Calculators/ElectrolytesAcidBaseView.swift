import SwiftUI

struct ElectrolytesAcidBaseView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var agNa = "140"
    @State private var agCl = "100"
    @State private var agHco3 = "24"
    @State private var agAlb = "4.0"

    @State private var caAlbumin = "8.5"
    @State private var caAlb = "4.0"

    @State private var winterCo2 = "15"

    @State private var osmNa = "140"
    @State private var osmGlu = "100"
    @State private var osmBun = "14"

    @State private var naCurrent = "125"
    @State private var naTarget = "135"
    @State private var naWeight = "70"
    @State private var naGender = "0"

    @State private var defNa = "125"
    @State private var defNaTarget = "140"
    @State private var defNaWt = "70"

    @State private var wdWeight = "70"
    @State private var wdNaFrom = "150"
    @State private var wdNaTo = "140"

    @State private var tbwAge = "60"
    @State private var tbwWeight = "70"
    @State private var tbwGender = "0"

    @State private var hyDuration = "24"
    @State private var hyFrom = "115"
    @State private var hyTo = "125"
    @State private var hyWeight = "70"

    @State private var uagNa = "42"
    @State private var uagK = "22"
    @State private var uagHco3 = "24"

    @State private var feUNa = "50"
    @State private var feSNa = "1.0"
    @State private var feUCr = "100"
    @State private var feSCr = "1.0"

    @State private var feCaU = "5"
    @State private var feCaS = "1.0"
    @State private var feUCa = "50"
    @State private var feSCa = "10"

    @State private var slNa = "140"
    @State private var slLipid = "0.5"

    @State private var spNa = "140"
    @State private var spProtein = "8.0"

    @State private var hhHco3 = "24"
    @State private var hhPco2 = "40"

    @State private var paoFiPaO2 = "95"
    @State private var paoFiFiO2 = "0.21"

    @State private var ddGap = "12"
    @State private var ddNa = "140"
    @State private var ddAlb = "4.0"

    @State private var cpPh = "7.40"
    @State private var cpAlb = "2.0"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "aniongap.htm":
            guard let n = Double(agNa), let c = Double(agCl),
                  let h = Double(agHco3), let a = Double(agAlb),
                  n > 0, c > 0, h > 0, a > 0 else {
                return "Enter valid values"
            }
            let g = n - (c + h)
            let corrected = g + 2.5 * (4.0 - a)
            let cat = g > 12 ? "Elevated" : g < 8 ? "Low" : "Normal"
            return String(format: "Anion Gap: %.0f mEq/L (%@)\nAlbumin-corrected: %.0f", g, cat, corrected)

        case "aniongapdelta.htm", "aniongapdeltagradient.htm":
            guard let d = Double(ddGap), let n = Double(ddNa),
                  let a = Double(ddAlb), n > 0, a > 0 else {
                return "Enter valid values"
            }
            let cAG = d + 12.0 * (4.0 - a)
            let bicarb = 24.0 - (cAG - 12.0)
            return String(format: "Corrected AG: %.0f, Expected HCO3: %.0f", cAG, bicarb)

        case "aniongaphypoalb.htm":
            guard let n = Double(agNa), let c = Double(agCl),
                  let h = Double(agHco3), let a = Double(agAlb),
                  n > 0, c > 0, h > 0, a > 0 else {
                return "Enter valid values"
            }
            let g = n - (c + h)
            let cG = g + 2.5 * (4.0 - a)
            return String(format: "AG: %.0f, Corrected: %.0f (albumin %.1f)", g, cG, a)

        case "calciumalbumin.htm", "calciumalbuminsi.htm":
            guard let c = Double(caAlbumin), let a = Double(caAlb),
                  c > 0, a > 0 else {
                return "Enter valid values"
            }
            return String(format: "Corrected Ca: %.2f mg/dL (albumin %.1f)", c + 0.8 * (4.0 - a), a)

        case "winterformula.htm":
            guard let h = Double(winterCo2), h > 0 else {
                return "Enter valid values"
            }
            return String(format: "Expected PaCO2 (Winter): %.0f ± 2 mmHg", 1.5 * h + 8.0)

        case "osmolality.htm":
            guard let n = Double(osmNa), let glu = Double(osmGlu),
                  let b = Double(osmBun), n > 0 else {
                return "Enter valid values"
            }
            return String(format: "Calculated Osmolality: %.1f mOsm/kg", 2.0 * n + glu / 18.0 + b / 2.8)

        case "sodiumcorrection.htm":
            guard let c = Double(naCurrent), let t = Double(naTarget),
                  let w = Double(naWeight), c > 0, w > 0 else {
                return "Enter valid values"
            }
            let tbw = naGender == "0" ? w * 0.6 : w * 0.5
            return String(format: "Na needed: %.0f mEq (%d → %d mEq/L)", (t - c) * tbw, Int(c), Int(t))

        case "sodiumdeficit.htm":
            guard let c = Double(defNa), let t = Double(defNaTarget),
                  let w = Double(defNaWt), c > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "Na deficit: %.0f mEq (%d → %d mEq/L)", (t - c) * w * 0.6, Int(c), Int(t))

        case "waterdeficit.htm":
            guard let w = Double(wdWeight), let c = Double(wdNaFrom),
                  let t = Double(wdNaTo), w > 0, c > 0, t > 0 else {
                return "Enter valid values"
            }
            return String(format: "Water deficit: %.1f L (Na %d → %d)", w * 0.6 * (c / t - 1.0), Int(c), Int(t))

        case "tbwwatson.htm":
            guard let a = Double(tbwAge), let w = Double(tbwWeight),
                  a > 0, w > 0 else {
                return "Enter valid values"
            }
            let tbw = tbwGender == "0" ? (0.6 - 0.002 * a) * w : (0.5 - 0.0015 * a) * w
            return String(format: "Total Body Water: %.1f L (Watson)", tbw)

        case "hyponatremiacorrect.htm":
            guard let d = Double(hyDuration), let f = Double(hyFrom),
                  let t = Double(hyTo), let w = Double(hyWeight),
                  d > 0, f > 0, w > 0 else {
                return "Enter valid values"
            }
            let tbw = w * 0.6
            let rate = (t - f) * tbw / (d * 24.0)
            return String(format: "Max correction: %.1f mEq/hr (limit: 8 mEq/24h)", rate)

        case "urineaniongap.htm":
            guard let n = Double(uagNa), let k = Double(uagK),
                  let h = Double(uagHco3), n > 0, k > 0 else {
                return "Enter valid values"
            }
            let g = n + k - h
            let i = g > 0 ? "Positive → Renal cause" : "Negative → Extra-renal (diarrhea)"
            return String(format: "Urine Anion Gap: %.0f (%@)", g, i)

        case "fractionalexcretionsodium.htm", "fractionalexcretionsodium_si.htm":
            guard let u = Double(feUNa), let s = Double(feSNa),
                  let uc = Double(feUCr), let sc = Double(feSCr),
                  u > 0, s > 0, uc > 0, sc > 0 else {
                return "Enter valid values"
            }
            let feNa = (uc / sc) / (u / s) * 100.0
            let cat = feNa < 1.0 ? "Pre-renal" : feNa < 3.0 ? "Intrinsic renal" : "Post-renal"
            return String(format: "FeNa: %.2f%% (%@)", feNa, cat)

        case "sodiumlipids.htm":
            guard let n = Double(slNa), let l = Double(slLipid),
                  n > 0, l > 0 else {
                return "Enter valid values"
            }
            return String(format: "Corrected Na (lipids): %.0f mEq/L", n + 0.3 * l * (n - 142.0))

        case "sodiumprotein.htm":
            guard let n = Double(spNa), let p = Double(spProtein),
                  n > 0, p > 0 else {
                return "Enter valid values"
            }
            return String(format: "Corrected Na (protein): %.0f mEq/L", n + 0.05 * p * (n - 142.0))

        case "hendersonghasselbalch.htm":
            guard let h = Double(hhHco3), let p = Double(hhPco2),
                  h > 0, p > 0 else {
                return "Enter valid values"
            }
            let pH = 6.1 + log10(h / (0.03 * p))
            let i = pH < 7.35 ? "Acidemia" : pH > 7.45 ? "Alkalemia" : "Normal"
            return String(format: "pH: %.2f (%@)", pH, i)

        case "pao2_fio2ratio.htm":
            guard let pa = Double(paoFiPaO2), let fi = Double(paoFiFiO2),
                  pa > 0, fi > 0 else {
                return "Enter valid values"
            }
            let r = pa / fi
            let a = r < 200 ? "Moderate ARDS" : r < 300 ? "Mild ARDS" : "No ARDS"
            return String(format: "PaO2/FiO2: %.0f (%@)", r, a)

        case "correctedph.htm":
            guard let p = Double(cpPh), let a = Double(cpAlb),
                  p > 0, a > 0 else {
                return "Enter valid values"
            }
            return String(format: "Corrected pH: %.3f (albumin %.1f)", p + 0.025 * (4.0 - a), a)

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("aniongap") {
                Section("Anion Gap") {
                    TextField("Sodium (mEq/L)", text: $agNa).keyboardType(.decimalPad)
                    TextField("Chloride (mEq/L)", text: $agCl).keyboardType(.decimalPad)
                    TextField("Bicarbonate (mEq/L)", text: $agHco3).keyboardType(.decimalPad)
                    TextField("Albumin (g/dL)", text: $agAlb).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("calcium") {
                Section("Corrected Calcium") {
                    TextField("Measured Calcium (mg/dL)", text: $caAlbumin).keyboardType(.decimalPad)
                    TextField("Albumin (g/dL)", text: $caAlb).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("winter") {
                Section("Winter Formula") {
                    TextField("Serum HCO3 (mEq/L)", text: $winterCo2).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("osmol") {
                Section("Serum Osmolality") {
                    TextField("Sodium (mEq/L)", text: $osmNa).keyboardType(.decimalPad)
                    TextField("Glucose (mg/dL)", text: $osmGlu).keyboardType(.decimalPad)
                    TextField("BUN (mg/dL)", text: $osmBun).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("sodium") && !calculator.fileName.lowercased().contains("lipid") && !calculator.fileName.lowercased().contains("protein") {
                Section("Sodium Correction") {
                    TextField("Current Na (mEq/L)", text: $naCurrent).keyboardType(.decimalPad)
                    TextField("Target Na (mEq/L)", text: $naTarget).keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $naWeight).keyboardType(.decimalPad)
                    Picker("Sex", selection: $naGender) {
                        Text("Male").tag("0"); Text("Female").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("tbw") || calculator.fileName.lowercased().contains("water") {
                Section("TBW / Water") {
                    TextField("Age (years)", text: $tbwAge).keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $tbwWeight).keyboardType(.decimalPad)
                    Picker("Sex", selection: $tbwGender) {
                        Text("Male").tag("0"); Text("Female").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("urine") {
                Section("Urine Anion Gap") {
                    TextField("Urine Na (mEq/L)", text: $uagNa).keyboardType(.decimalPad)
                    TextField("Urine K (mEq/L)", text: $uagK).keyboardType(.decimalPad)
                    TextField("Urine HCO3 (mEq/L)", text: $uagHco3).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("fraction") {
                Section("Fractional Excretion of Na") {
                    TextField("Urine Na (mEq/L)", text: $feUNa).keyboardType(.decimalPad)
                    TextField("Serum Na (mEq/L)", text: $feSNa).keyboardType(.decimalPad)
                    TextField("Urine Creatinine (mg/dL)", text: $feUCr).keyboardType(.decimalPad)
                    TextField("Serum Creatinine (mg/dL)", text: $feSCr).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("henders") {
                Section("Henderson-Hasselbalch") {
                    TextField("HCO3 (mEq/L)", text: $hhHco3).keyboardType(.decimalPad)
                    TextField("PaCO2 (mmHg)", text: $hhPco2).keyboardType(.decimalPad)
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
