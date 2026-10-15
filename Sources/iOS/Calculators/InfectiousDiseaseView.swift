import SwiftUI

struct InfectiousDiseaseView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    @State private var centorFever = "0"
    @State private var centorNodes = "0"
    @State private var centorExudate = "0"
    @State private var centorCough = "0"
    @State private var centorAge="45"
    @State private var anthExposure = "0"
    @State private var anthImmunocompromised = "0"
    @State private var anthSkinLesion = "0"
    @State private var psiAge = "65"
    @State private var psiBun = "30"
    @State private var psiComorbid = "0"
    @State private var psiNeuro = "0"
    @State private var psiResp = "0"
    @State private var psiCv = "0"
    @State private var psiRenal = "0"
    @State private var psiPneumonia = "0"
    @State private var psiEmpyema = "0"
    @State private var csfAge = "30"
    @State private var csfWbc = "100"
    @State private var csfProtein = "50"
    @State private var smallPoxExposure = "0"
    @State private var smallPoxVaccination = "0"
    @State private var smallPoxSymptoms = "0"
    
    var result: String {
        switch calculator.fileName.lowercased() {
        case "centormcisaac.htm":
            guard let age = Double(centorAge) else { return "Enter age" }
            var score = (Double(centorFever) ?? 0) + (Double(centorNodes) ?? 0) + (Double(centorExudate) ?? 0)
            if age < 15 { score += 1 }
            if age > 44 { score -= 1 }
            score = max(0, min(score, 5))
            let probability = score == 0 ? "<3%" : score == 1 ? "3-9%" : score == 2 ? "9-24%" : score == 3 ? "24-51%" : score == 4 ? "51-90%" : ">90%"
            return String(format: "Centor-McIsaac: %.0f/5 (Strep probability: %@)", score, probability)
        case "anthraxscreening.htm":
            let score = (Double(anthExposure) ?? 0) + (Double(anthImmunocompromised) ?? 0) + (Double(anthSkinLesion) ?? 0)
            let risk = score >= 3 ? "High - isolate immediately" : score >= 1 ? "Moderate - further workup" : "Low - routine care"
            return String(format: "Anthrax Risk: %.0f/3 (%@)", score, risk)
        case "communityacquiredpneumonia.htm":
            guard let age = Double(psiAge), let bun = Double(psiBun), age >= 0, bun >= 0 else {
                return "Enter valid values"
            }
            var score = 0.0
            if age >= 75 { score += 1 } else if age >= 65 { score += 1 }
            score += (Double(psiComorbid) ?? 0) + (Double(psiNeuro) ?? 0) + (Double(psiResp) ?? 0) + (Double(psiCv) ?? 0) + (Double(psiRenal) ?? 0)
            score += (Double(psiPneumonia) ?? 0) + (Double(psiEmpyema) ?? 0)
            let cls = score <= 1 ? "Class I" : score <= 2 ? "Class II" : score <= 3 ? "Class III" : score <= 4 ? "Class IV" : "Class V"
            let mortality = score <= 1 ? "0.1%" : score <= 2 ? "0.6%" : score <= 3 ? "1.7%" : score <= 4 ? "8.2%" : "28.9%"
            return String(format: "PSI: %@  (30-day mortality: %@)\n%@  (%@)", cls, mortality, "Disposition", cls == "Class I" ? "Outpatient" : "Admit")
        case "csfwbc.htm":
            guard let age = Double(csfAge), let wbc = Double(csfWbc), let protein = Double(csfProtein), age >= 0, wbc >= 0, protein >= 0 else {
                return "Enter valid values"
            }
            let expected = protein / 1000.0 * age / 10.0
            let abnormal = expected > 0.05 ? "Abnormal (likely viral/infectious)" : "Normal"
            return String(format: "Age: %@, WBC: %@/µL, Protein: %@ g/dL\nExpected: %.2f (%@)", csfAge, csfWbc, csfProtein, expected, abnormal)
        case "smallpox.htm":
            let score = (Double(smallPoxExposure) ?? 0) + (Double(smallPoxVaccination) ?? 0) + (Double(smallPoxSymptoms) ?? 0)
            let risk = score >= 3 ? "High probability - isolate" : score >= 1 ? "Possible - further evaluation" : "Unlikely"
            return String(format: "Smallpox Risk: %.0f/3 (%@)", score, risk)
        default: return "Not yet implemented"
        }
    }
    
    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("centor") {
                Section("Centor-McIsaac Score (pharyngitis)") {
                    TextField("Age (years)", text: $centorAge).keyboardType(.decimalPad)
                    Picker("Fever >38°C", selection: $centorFever) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Tender anterior nodes", selection: $centorNodes) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Tonsillar exudate", selection: $centorExudate) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Absence of cough", selection: $centorCough) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("anthrax") {
                Section("Anthrax Screening") {
                    Picker("Known/exposed to anthrax", selection: $anthExposure) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Immunocompromised", selection: $anthImmunocompromised) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Skin lesion (eschar)", selection: $anthSkinLesion) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("pneumonia") {
                Section("PSI - Pneumonia Severity Index") {
                    TextField("Age (years)", text: $psiAge).keyboardType(.decimalPad)
                    TextField("BUN (mg/dL)", text: $psiBun).keyboardType(.decimalPad)
                    Picker("Comorbid conditions", selection: $psiComorbid) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Neurologic disorder", selection: $psiNeuro) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("RR ≥30 or BP <90/60", selection: $psiResp) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Cardiovascular disease", selection: $psiCv) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Renal/liver disease", selection: $psiRenal) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Pneumonia on CXR", selection: $psiPneumonia) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
                    Picker("Pleural effusion", selection: $psiEmpyema) { Text("No").tag("0"); Text("Yes").tag("1") }.pickerStyle(.segmented)
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
