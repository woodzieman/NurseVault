import SwiftUI

struct RenalView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var cgAge = "60"
    @State private var cgWeight = "70"
    @State private var cgSex = "0"
    @State private var cgCreat = "1.2"

    @State private var cgSICreat = "1.2"

    @State private var sanAge = "60"
    @State private var sanWeight = "70"
    @State private var sanSex = "0"
    @State private var sanCreat = "1.2"

    @State private var epiAge = "60"
    @State private var epiRace = "0"
    @State private var epiSex = "0"
    @State private var epiCreat = "1.2"
    @State private var epiCyst = "1.0"

    @State private var mdrdAge = "60"
    @State private var mdrdSex = "0"
    @State private var mdrdRace = "0"
    @State private var mdrdCreat = "1.2"
    @State private var mdrdAlb = "4.0"

    @State private var ktVU = "45"
    @State private var ktVE = "5"
    @State private var ktVD = "0.04"
    @State private var ktVT = "42"

    @State private var ureaVd = "42"
    @State private var ureaIn = "45"
    @State private var ureaOut = "10"

    @State private var protU = "200"
    @State private var protV = "1"

    @State private var volU = "42"
    @State private var volG = "0.01"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "creatinineclearance.htm":
            guard let a = Double(cgAge), let w = Double(cgWeight), let c = Double(cgCreat),
                  a > 0, w > 0, c > 0 else {
                return "Enter valid values"
            }
            let co = (140.0 - a) * w / (72.0 * c)
            let fin = co * (cgSex == "0" ? 1.0 : 0.75)
            return String(format: "CrCl (Cockcroft-Gault): %.0f mL/min", fin)

        case "creatinineclearance_si.htm":
            guard let c = Double(cgSICreat), c > 0 else {
                return "Enter valid values"
            }
            let a = Double(cgAge) ?? 60
            let w = Double(cgWeight) ?? 70
            let co = (140.0 - a) * w / (72.0 * c / 144.0)
            let fin = co * (cgSex == "0" ? 1.0 : 0.75)
            return String(format: "CrCl (SI): %.0f mL/min", fin)

        case "sanakacreatinineclearance.htm":
            guard let a = Double(sanAge), let w = Double(sanWeight), let c = Double(sanCreat),
                  a > 0, w > 0, c > 0 else {
                return "Enter valid values"
            }
            let co = (140.0 - a) * w / (72.0 * c * (sanSex == "0" ? 1.0 : 0.75))
            return String(format: "Sanaka CrCl: %.0f mL/min", co)

        case "gfr-epi.htm":
            guard let a = Double(epiAge), let c = Double(epiCreat), a > 0, c > 0 else {
                return "Enter valid values"
            }
            let k = min(c, 0.9)
            let s = epiSex == "0" ? 1.0 : 0.742
            let epi = 142.0 * pow(k, -0.241) * pow(a, -1.209) * s
            return String(format: "eGFR (EPI): %.0f mL/min/1.73m²", epi)

        case "gfr-epi2021.htm":
            guard let c = Double(epiCreat), let a = Double(epiAge), a > 0, c > 0 else {
                return "Enter valid values"
            }
            let k = min(c, 0.9)
            let s = epiSex == "0" ? 1.0 : 1.012
            let r = epiRace == "0" ? 1.0 : 1.159
            let epi = 142.0 * pow(k, -0.241) * pow(a, -1.209) * s * r
            return String(format: "eGFR 2021: %.0f mL/min/1.73m²", epi)

        case "gfr-epi-cystatin.htm":
            guard let c = Double(epiCreat), let cy = Double(epiCyst), let a = Double(epiAge),
                  a > 0, c > 0, cy > 0 else {
                return "Enter valid values"
            }
            let k = min(c, 0.9)
            let s = epiSex == "0" ? 1.0 : 0.811
            let epi = 142.0 * pow(k, -0.241) * pow(a, -1.209) * pow(0.604, cy) * s
            return String(format: "eGFR (Cystatin): %.0f mL/min/1.73m²", epi)

        case "mdrd.htm":
            guard let a = Double(mdrdAge), let c = Double(mdrdCreat), a > 0, c > 0 else {
                return "Enter valid values"
            }
            let k = min(c, 0.9)
            let s = mdrdSex == "0" ? 1.0 : 0.742
            let r = mdrdRace == "0" ? 1.0 : 1.212
            return String(format: "MDRD GFR: %.0f mL/min/1.73m²", 175.0 * pow(k, -1.154) * pow(a, -0.204) * s * r)

        case "gfr-epi-full.htm":
            guard let a = Double(mdrdAge), let c = Double(mdrdCreat), a > 0, c > 0 else {
                return "Enter valid values"
            }
            return String(format: "Full MDRD: %.0f mL/min/1.73m²", 175.0 * pow(min(c, 0.9), -1.154) * pow(a, -0.204))

        case "ktv.htm":
            guard let u = Double(ktVU), let e = Double(ktVE), let v = Double(ktVD), let t = Double(ktVT),
                  u > 0, e > 0, v > 0, t > 0 else {
                return "Enter valid values"
            }
            let ktV = (u * v) / t
            return String(format: "Kt/V: %.3f", ktV / e)

        case "ureareduction.htm":
            guard let i = Double(ureaIn), let o = Double(ureaOut), let v = Double(ureaVd),
                  i > 0, o > 0, v > 0 else {
                return "Enter valid values"
            }
            let urr = (i - o) / i * 100.0
            return String(format: "URR: %.1f%%", urr)

        case "urinaryproteinexcretion.htm":
            guard let u = Double(protU), let v = Double(protV), u > 0, v > 0 else {
                return "Enter valid values"
            }
            return String(format: "Protein excretion: %.0f mg/24h", u * v)

        case "volumeofureadistribution.htm":
            guard let u = Double(volU), let g = Double(volG), u > 0, g > 0 else {
                return "Enter valid values"
            }
            return String(format: "Vd Urea: %.1f L", u / g)

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("creatinine") {
                Section("Creatinine Clearance (Cockcroft-Gault)") {
                    TextField("Age (years)", text: $cgAge).keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $cgWeight).keyboardType(.decimalPad)
                    TextField("Serum Creatinine (mg/dL)", text: $cgCreat).keyboardType(.decimalPad)
                    Picker("Sex", selection: $cgSex) {
                        Text("Male").tag("0"); Text("Female").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("gfr") || calculator.fileName.lowercased().contains("mdrd") {
                Section("eGFR (EPI/MDRD)") {
                    TextField("Age (years)", text: $epiAge).keyboardType(.decimalPad)
                    TextField("Serum Creatinine (mg/dL)", text: $epiCreat).keyboardType(.decimalPad)
                    TextField("Cystatin C (mg/L)", text: $epiCyst).keyboardType(.decimalPad)
                    Picker("Sex", selection: $epiSex) {
                        Text("Male").tag("0"); Text("Female").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("ktv") {
                Section("Kt/V") {
                    TextField("Pre-dialysis Urea (g/L)", text: $ktVU).keyboardType(.decimalPad)
                    TextField("Post-dialysis Urea (g/L)", text: $ktVE).keyboardType(.decimalPad)
                    TextField("Volume of Distribution (L)", text: $ktVD).keyboardType(.decimalPad)
                    TextField("Dialysis Time (h)", text: $ktVT).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("urea") || calculator.fileName.lowercased().contains("urr") {
                Section("Urea Reduction Ratio (URR)") {
                    TextField("Pre-dialysis BUN (mg/dL)", text: $ureaIn).keyboardType(.decimalPad)
                    TextField("Post-dialysis BUN (mg/dL)", text: $ureaOut).keyboardType(.decimalPad)
                    TextField("Volume of Distribution (L)", text: $ureaVd).keyboardType(.decimalPad)
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
