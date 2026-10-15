import SwiftUI

struct HepaticView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var cpAge = "60"
    @State private var cpBil = "2.0"
    @State private var cpAlb = "3.0"
    @State private var cpINR = "1.5"
    @State private var cpAscites = "0"
    @State private var cpEnceph = "0"

    @State private var mel3Bil = "2.0"
    @State private var mel3INR = "1.5"
    @State private var mel3Na = "135"
    @State private var mel3Alb = "3.5"
    @State private var mel3Creat = "1.5"

    @State private var fib4Age = "55"
    @State private var fib4AST = "30"
    @State private var fib4ALT = "25"
    @State private var fib4Platelets = "250"

    @State private var gipssAlb = "3.0"
    @State private var gipssBil = "2.0"
    @State private var gipssINR = "1.5"

    @State private var hepDFAge = "60"
    @State private var hepDFBil = "2.0"
    @State private var hepDFINR = "1.5"
    @State private var hepDFRenal = "1.0"

    @State private var milanNodules = "1"
    @State private var milanMaxDiam = "3.0"

    // MARK: - Autoimmune Hepatitis State Properties
    @State private var aihAutoAb = false
    @State private var aihNegHbsAg = true
    @State private var aihIggGdL = "1.5"
    @State private var aihHist: Double = 2
    @State private var aihNegOther = true

    var result: String {
        switch calculator.fileName.lowercased() {
        case "childpugh.htm":
            guard let bil = Double(cpBil), let alb = Double(cpAlb),
                  let inr = Double(cpINR), bil > 0, alb > 0, inr > 0 else {
                return "Enter valid values"
            }
            var s = 0
            if bil > 3.0 { s += 3 } else if bil > 1.7 { s += 2 } else { s += 1 }
            if alb < 2.8 { s += 3 } else if alb > 2.8 && alb <= 3.5 { s += 2 } else { s += 1 }
            if inr > 1.7 { s += 3 } else if inr > 1.3 { s += 2 } else { s += 1 }
            if cpAscites == "1" { s += 2 }
            if cpEnceph == "1" { s += 3 }
            let cls = s <= 6 ? "A" : s <= 9 ? "B" : "C"
            let mort = cls == "A" ? "85% at 1yr" : cls == "B" ? "45% at 1yr" : "20% at 1yr"
            return String(format: "Child-Pugh: %d (Class %@, 1-yr survival: %@)", s, cls, mort)

        case "meld.htm":
            guard let bil = Double(mel3Bil), let inr = Double(mel3INR),
                  let cre = Double(mel3Creat), bil > 0, inr > 0, cre >= 0 else {
                return "Enter valid values"
            }
            let raw = 3.78 * log(max(bil, 1.0)) + 11.2 * log(max(inr, 1.0)) + 9.57 * log(max(cre, 1.0)) + 10.0
            let m = max(6, min(Int(round(raw)), 40))
            let mort = m <= 20 ? "~6%" : m <= 30 ? "~20%" : m <= 40 ? "~72%" : "~90%"
            return String(format: "MELD Score: %d (3-mo mortality: %@)", m, mort)

        case "meld3.htm":
            guard let bil = Double(mel3Bil), let inr = Double(mel3INR),
                  let na = Double(mel3Na), let alb = Double(mel3Alb),
                  let cre = Double(mel3Creat), bil > 0, inr > 0, na > 0, alb > 0, cre >= 0 else {
                return "Enter valid values"
            }
            let raw = 3.78 * log(max(bil, 1.0)) + 11.2 * log(max(inr, 1.0)) + 9.57 * log(max(cre, 1.0)) + 10.0
            let naAdj = max(1.0 - 0.0391 * (max(125.0, na) - 135.0), 0.8)
            let m = max(6, min(Int(round(raw * naAdj)), 40))
            return String(format: "MELD 3.0: %d (includes Na and albumin)", m)

        case "fib-4.htm":
            guard let age = Double(fib4Age), let ast = Double(fib4AST),
                  let alt = Double(fib4ALT), let pl = Double(fib4Platelets),
                  age > 0, ast > 0, alt > 0, pl > 0 else {
                return "Enter valid values"
            }
            let fib4 = (age * ast) / (alt * sqrt(Double(pl)))
            let fib = fib4 < 1.455 ? "Low risk" : fib4 < 3.25 ? "Intermediate risk" : "High risk (likely fibrosis)"
            return String(format: "FIB-4: %.3f (%@)", fib4, fib)

        case "gipssscore.htm":
            guard let alb = Double(gipssAlb), let bil = Double(gipssBil),
                  let inr = Double(gipssINR), alb > 0, bil > 0, inr > 0 else {
                return "Enter valid values"
            }
            let gipss = alb * 2.0 + (4.0 - alb) * 0.5 + (1.0 - (inr - 1.0)) * 2.0 + (4.0 - bil) * 1.0
            return String(format: "GIPSS: %.1f", gipss)

        case "hepatitissf.htm":
            guard let age = Double(hepDFAge), let bil = Double(hepDFBil),
                  let inr = Double(hepDFINR), let cre = Double(hepDFRenal),
                  age > 0, bil > 0, inr > 0, cre > 0 else {
                return "Enter valid values"
            }
            var sf = age * 0.2
            if bil > 3.0 { sf += 1.0 }
            if inr > 2.0 { sf += 1.0 }
            if cre > 1.0 { sf += 1.0 }
            let risk = sf > 3.0 ? "High risk" : "Low risk"
            return String(format: "SF: %.1f (%@)", sf, risk)

        case "milancriteria.htm":
            let n = Int(milanNodules) ?? 1
            let d = Double(milanMaxDiam) ?? 3.0
            let ok = (n == 1 && d <= 5.0) || (n >= 1 && n <= 3 && d <= 3.0)
            let status = ok ? "Meets Milan Criteria" : "Exceeds Milan Criteria"
            return String(format: "Milan: %@ (n=%d, max=%.1f cm)", status, n, d)

        case "autoimmunehepatitis.htm":
            return calcAutoimmuneHepatitis()

        default:
            return "Not yet implemented"
        }
    }

    // MARK: - Calculation Functions

    func calcAutoimmuneHepatitis() -> String {
        var s = 0
        if !aihAutoAb { s += 2 }; if aihNegHbsAg { s += 2 }
        if let igg = Double(aihIggGdL), igg > 1.1 { s += 1 }; if aihHist >= 2.0 { s += 2 }; if aihHist == 1.0 { s += 1 }
        if aihNegOther { s += 1 }
        let dx = s >= 7 ? "Definite AIH" : s >= 4 ? "Probable" : "Unlikely"
        return String(format: "Score: %d (%@)", s, dx)
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("child") {
                Section("Child-Pugh Score") {
                    TextField("Bilirubin (mg/dL)", text: $cpBil).keyboardType(.decimalPad)
                    TextField("Albumin (g/dL)", text: $cpAlb).keyboardType(.decimalPad)
                    TextField("INR", text: $cpINR).keyboardType(.decimalPad)
                    Picker("Ascites", selection: $cpAscites) {
                        Text("None").tag("0"); Text("Mild").tag("1"); Text("Severe").tag("2")
                    }.pickerStyle(.segmented)
                    Picker("Encephalopathy", selection: $cpEnceph) {
                        Text("None").tag("0"); Text("Grade 1-2").tag("1"); Text("Grade 3-4").tag("2")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("meld") {
                Section("MELD Score") {
                    TextField("Bilirubin (mg/dL)", text: $mel3Bil).keyboardType(.decimalPad)
                    TextField("INR", text: $mel3INR).keyboardType(.decimalPad)
                    TextField("Creatinine (mg/dL)", text: $mel3Creat).keyboardType(.decimalPad)
                    TextField("Sodium (mmol/L)", text: $mel3Na).keyboardType(.decimalPad)
                    TextField("Albumin (g/dL)", text: $mel3Alb).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("fib") {
                Section("FIB-4 Score") {
                    TextField("Age (years)", text: $fib4Age).keyboardType(.decimalPad)
                    TextField("AST (U/L)", text: $fib4AST).keyboardType(.decimalPad)
                    TextField("ALT (U/L)", text: $fib4ALT).keyboardType(.decimalPad)
                    TextField("Platelets (×10³/µL)", text: $fib4Platelets).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("milan") {
                Section("Milan Criteria (Liver Transplant)") {
                    TextField("Number of Nodules", text: $milanNodules).keyboardType(.numberPad)
                    TextField("Max Nodule Diameter (cm)", text: $milanMaxDiam).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("autoimmune") {
                Section("Autoimmune Hepatitis Score") {
                    Toggle("Autoantibodies present (+2 if absent)", isOn: $aihAutoAb)
                    Toggle("HBsAg negative (+2)", isOn: $aihNegHbsAg)
                    TextField("IgG level (g/dL)", text: $aihIggGdL).keyboardType(.decimalPad)
                    Text("Histology score (0-3): \(Int(aihHist))")
                    Slider(value: $aihHist, in: 0...3, step: 1)
                    Toggle("Other causes excluded (+1)", isOn: $aihNegOther)
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
