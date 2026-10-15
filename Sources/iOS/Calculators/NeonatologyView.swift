import SwiftUI

struct NeonatologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var apgA = "2"
    @State private var apgP = "2"
    @State private var apgG = "2"
    @State private var apgAc = "2"
    @State private var apgR = "2"

    @State private var westAir = "3"
    @State private var westRetr = "3"
    @State private var westCyan = "0"
    @State private var westBarking = "2"

    @State private var neonSepMaternal = "0"
    @State private var neonSepGBM = "0"
    @State private var neonSepROM = "7"
    @State private var neonSepMatFever = "0"
    @State private var neonSepMatTachy = "0"
    @State private var neonSepNeonTachy = "0"
    @State private var neonSepLeukopenia = "0"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "apgarscore.htm":
            let a = Int(apgA) ?? 0
            let p = Int(apgP) ?? 0
            let g = Int(apgG) ?? 0
            let ac = Int(apgAc) ?? 0
            let r = Int(apgR) ?? 0
            let total = a + p + g + ac + r
            let sev = total >= 7 ? "Normal" : total >= 4 ? "Moderate depression" : "Severe depression"
            return String(format: "Apgar: %d/10 (%@)", total, sev)

        case "westleycroup.htm":
            let air = Int(westAir) ?? 0
            let retr = Int(westRetr) ?? 0
            let cyan = Int(westCyan) ?? 0
            let bark = Int(westBarking) ?? 0
            let total = air + retr + cyan + bark
            let sev = total <= 1 ? "Mild" : total <= 4 ? "Moderate" : total <= 8 ? "Severe" : "Very severe"
            return String(format: "Westley Croup: %d (%@)", total, sev)

        case "neonatalsepsis.htm":
            var s = 0
            if neonSepMaternal == "1" { s += 1 }
            if neonSepGBM == "1" { s += 1 }
            if let rom = Int(neonSepROM), rom >= 18 { s += 1 }
            if neonSepMatFever == "1" { s += 1 }
            if neonSepMatTachy == "1" { s += 1 }
            if neonSepNeonTachy == "1" { s += 1 }
            if neonSepLeukopenia == "1" { s += 1 }
            let r = s >= 4 ? "High risk - culture and treat" : s >= 2 ? "Moderate - monitor" : "Low risk"
            return String(format: "Neonatal Sepsis Risk: %d/7 (%@)", s, r)

        case "neonatalhyperbilirubin.htm":
            return "Check bilirubin nomogram for gestational age and hour of life"

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("apgar") {
                Section("Apgar Score") {
                    Picker("Appearance", selection: $apgA) {
                        Text("Absent").tag("0"); Text("Some").tag("1"); Text("Active").tag("2")
                    }.pickerStyle(.segmented)
                    Picker("Pulse", selection: $apgP) {
                        Text("Absent").tag("0"); Text("<100").tag("1"); Text(">100").tag("2")
                    }.pickerStyle(.segmented)
                    Picker("Grimace", selection: $apgG) {
                        Text("No").tag("0"); Text("Grimace").tag("1"); Text("Cough").tag("2")
                    }.pickerStyle(.segmented)
                    Picker("Activity", selection: $apgAc) {
                        Text("Flaccid").tag("0"); Text("Some").tag("1"); Text("Active").tag("2")
                    }.pickerStyle(.segmented)
                    Picker("Respiration", selection: $apgR) {
                        Text("Absent").tag("0"); Text("Irregular").tag("1"); Text("Good").tag("2")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("westley") {
                Section("Westley Croup Score") {
                    TextField("Airway (0-3)", text: $westAir).keyboardType(.numberPad)
                    TextField("Retractions (0-3)", text: $westRetr).keyboardType(.numberPad)
                    TextField("Cyanosis (0-1)", text: $westCyan).keyboardType(.numberPad)
                    TextField("Barking (0-3)", text: $westBarking).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("sepsis") {
                Section("Neonatal Sepsis Risk") {
                    Picker("GBS unknown/positive", selection: $neonSepMaternal) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("GBM > 18h", selection: $neonSepGBM) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    TextField("ROM duration (hrs)", text: $neonSepROM).keyboardType(.decimalPad)
                    Picker("Maternal fever >38°C", selection: $neonSepMatFever) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("Maternal tachycardia", selection: $neonSepMatTachy) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("Neonatal tachycardia", selection: $neonSepNeonTachy) {
                        Text("No").tag("0"); Text("Yes").tag("1")
                    }.pickerStyle(.segmented)
                    Picker("Leukopenia", selection: $neonSepLeukopenia) {
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
