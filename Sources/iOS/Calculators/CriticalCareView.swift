import SwiftUI

struct CriticalCareView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var age = "60"
    @State private var temp = "37"
    @State private var creatinine = "1.5"
    @State private var cv = "5"
    @State private var cerebral = "2"

    @State private var bisapAge = "60"
    @State private var bisapBUN = "25"
    @State private var bisapSIRS = "0"
    @State private var bisapPSA = "0"
    @State private var bisapAge65 = "0"

    @State private var parkArea = "20"
    @State private var parkPercent = "40"

    @State private var modsPaof = "350"
    @State private var modsPlt = "150"
    @State private var modsMap = "80"
    @State private var modsGcs = "14"
    @State private var modsCre = "1.0"
    @State private var modsBil = "1.0"

    @State private var sofaPaof = "300"
    @State private var sofaPlt = "150"
    @State private var sofaMap = "80"
    @State private var sofaGcs = "15"
    @State private var sofaCre = "1.0"
    @State private var sofaBil = "1.0"

    @State private var qsofaRR = "0"
    @State private var qsofaAMS = "0"
    @State private var qsofaSys = "0"

    @State private var medsHypot = "0"
    @State private var medsAMS = "0"
    @State private var medsLeuko = "0"
    @State private var medsThromb = "0"
    @State private var medsHypotherm = "0"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "apachescore.htm":
            guard let a = Double(age), let c = Double(creatinine),
                  a > 0, c > 0 else { return "Enter valid values" }
            let apache = a >= 60 ? 2.0 : c >= 55 ? 1.0 : 0.0
            let m = apache > 8.0 ? "High (35%)" : apache > 5.0 ? "Moderate (15%)" : "Low (5%)"
            return String(format: "APACHE II: %.1f (Mortality: %@)", apache, m)

        case "bisapscore.htm":
            guard let a = Double(bisapAge), let bun = Double(bisapBUN),
                  a > 0, bun > 0 else { return "Enter valid values" }
            var s = 0.0
            if a >= 65 { s += 1 }
            if bun >= 25 { s += 1 }
            if let sirs = Int(bisapSIRS), sirs >= 1 { s += 1 }
            if let psa = Int(bisapPSA), psa >= 1 { s += 1 }
            let m = s >= 3.0 ? "High risk" : "Low risk"
            return String(format: "BISAP: %d (%@)", Int(s), m)

        case "burninjuryfluidparkland.htm":
            guard let area = Double(parkArea), let pct = Double(parkPercent),
                  area > 0, pct > 0 else { return "Enter valid values" }
            let fluid = 4.0 * area * pct / 100.0
            return String(format: "Parkland: %.0f mL (first 24h)\nFirst 8h: %.0f mL", fluid, fluid / 2.0)

        case "mods.htm":
            guard let pa = Double(modsPaof), let pl = Double(modsPlt),
                  let ma = Double(modsMap), let gc = Double(modsGcs),
                  let cre = Double(modsCre), let bi = Double(modsBil),
                  pa > 0, pl > 0 else { return "Enter valid values" }
            var s = 0
            if pa < 300 { s += 1 }
            if pl <= 120 { s += 1 }
            if ma < 70 { s += 1 }
            if gc < 10 { s += 1 }
            if cre > 1.2 { s += 1 }
            if bi > 2.0 { s += 1 }
            return String(format: "MODS: %d", s)

        case "sofa.htm":
            guard let pa = Double(sofaPaof), let pl = Double(sofaPlt),
                  let ma = Double(sofaMap), let gc = Double(sofaGcs),
                  let cre = Double(sofaCre), let bi = Double(sofaBil),
                  pa > 0, pl > 0 else { return "Enter valid values" }
            var s = 0
            if pa < 300 { s += 1 }
            if pa < 200 { s += 2 }
            if pa < 100 { s += 3 }
            if pl <= 120 { s += 1 }
            if pl <= 50 { s += 2 }
            if pl <= 20 { s += 3 }
            if ma < 70 { s += 1 }
            if gc < 10 { s += 1 }
            if gc < 6 { s += 2 }
            if gc < 3 { s += 3 }
            if cre > 1.2 { s += 1 }
            if cre > 2.0 { s += 2 }
            if cre > 3.5 { s += 3 }
            if bi > 2.0 { s += 1 }
            if bi > 6.0 { s += 2 }
            if bi > 12.0 { s += 3 }
            return String(format: "SOFA: %d", s)

        case "qsofa.htm":
            let s = (Int(qsofaRR) ?? 0) + (Int(qsofaAMS) ?? 0) + (Int(qsofaSys) ?? 0)
            let r = s >= 2 ? "High risk (consider ICU)" : "Low risk"
            return String(format: "qSOFA: %d (%@)", s, r)

        case "medsscore.htm":
            let s = (Int(medsHypot) ?? 0) + (Int(medsAMS) ?? 0) + (Int(medsLeuko) ?? 0)
                  + (Int(medsThromb) ?? 0) + (Int(medsHypotherm) ?? 0)
            return String(format: "MEDS: %d (Mortality: %.0f%%)", s, Double(min(10 + s * 15, 95)))

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("apache") {
                Section("APACHE II") {
                    TextField("Age (years)", text: $age).keyboardType(.decimalPad)
                    TextField("Core Temp (°C)", text: $temp).keyboardType(.decimalPad)
                    TextField("Creatinine (mg/dL)", text: $creatinine).keyboardType(.decimalPad)
                    TextField("CV score (0-3)", text: $cv).keyboardType(.numberPad)
                    TextField("Cerebral (0-4)", text: $cerebral).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("bisap") {
                Section("BISAP Score") {
                    TextField("Age (years)", text: $bisapAge).keyboardType(.decimalPad)
                    TextField("BUN (mg/dL)", text: $bisapBUN).keyboardType(.decimalPad)
                    TextField("SIRS criteria (0-4)", text: $bisapSIRS).keyboardType(.numberPad)
                    TextField("Pleural effusion (0/1)", text: $bisapPSA).keyboardType(.numberPad)
                    TextField("Age ≥ 65 (0/1)", text: $bisapAge65).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("parkland") {
                Section("Parkland Burn Formula") {
                    TextField("Burn Area (% TBSA)", text: $parkArea).keyboardType(.decimalPad)
                    TextField("Percent Body Surface", text: $parkPercent).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("mods") {
                Section("MODS Score") {
                    TextField("PaO2/FiO2", text: $modsPaof).keyboardType(.decimalPad)
                    TextField("Platelets (×10³/µL)", text: $modsPlt).keyboardType(.decimalPad)
                    TextField("MAP (mmHg)", text: $modsMap).keyboardType(.decimalPad)
                    TextField("GCS", text: $modsGcs).keyboardType(.decimalPad)
                    TextField("Creatinine (mg/dL)", text: $modsCre).keyboardType(.decimalPad)
                    TextField("Bilirubin (mg/dL)", text: $modsBil).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("sofa") {
                Section("SOFA Score") {
                    TextField("PaO2/FiO2", text: $sofaPaof).keyboardType(.decimalPad)
                    TextField("Platelets (×10³/µL)", text: $sofaPlt).keyboardType(.decimalPad)
                    TextField("MAP (mmHg)", text: $sofaMap).keyboardType(.decimalPad)
                    TextField("GCS", text: $sofaGcs).keyboardType(.decimalPad)
                    TextField("Creatinine (mg/dL)", text: $sofaCre).keyboardType(.decimalPad)
                    TextField("Bilirubin (mg/dL)", text: $sofaBil).keyboardType(.decimalPad)
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
