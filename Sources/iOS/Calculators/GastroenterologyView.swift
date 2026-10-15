import SwiftUI

struct GastroenterologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var cdaBSymptoms = "2"
    @State private var cdaBleeding = "2"
    @State private var cdaMucus = "2"
    @State private var cdaAbundance = "2"

    @State private var barrettYears = "10"
    @State private var barrettGender = "0"

    @State private var das28Swollen = "8"
    @State private var das28Tender = "12"
    @State private var das28Pain = "50"
    @State private var das28CRP = "25"

    // MARK: - ABC Score State Properties
    @State private var abcAmsl = "4"
    @State private var abcCRP = "10"
    @State private var abcBUN = "20"
    @State private var abcAspartate = "40"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "cda.htm":
            let bs = Double(cdaBSymptoms) ?? 0
            let bl = Double(cdaBleeding) ?? 0
            let mu = Double(cdaMucus) ?? 0
            let ab = Double(cdaAbundance) ?? 0
            let cda = 8 * (24 - bs) + bl * 6 + mu * 5 + ab * 3
            let rem = cda <= 150 ? "Remission" : cda <= 220 ? "Mild" : cda <= 450 ? "Moderate" : "Severe"
            return String(format: "CDAI: %.0f (%@)", cda, rem)

        case "barrettprog.htm":
            guard let yrs = Double(barrettYears), yrs >= 0 else {
                return "Enter years of Barrett's"
            }
            let rate = barrettGender == "0" ? 0.33 : 0.5
            return String(format: "Annual cancer risk: %.2f%%\nLifetime risk: %.1f%% (%.0f yrs)", rate, yrs * rate / 100.0, yrs)

        case "das28.htm":
            guard let sw = Double(das28Swollen), let te = Double(das28Tender),
                  let pg = Double(das28Pain), let c = Double(das28CRP),
                  sw >= 0, te >= 0, pg >= 0, c >= 0 else {
                return "Enter valid values"
            }
            let das28 = 0.56 * sqrt(sw) + 0.28 * sqrt(te) + 0.36 * sqrt(pg) + 0.014 * c + 0.64
            let status = das28 <= 2.6 ? "Remission" : das28 <= 3.2 ? "Low activity" : das28 <= 5.1 ? "Moderate activity" : "High activity"
            return String(format: "DAS28: %.2f (%@)",das28, status)

        case "abc.htm":
            return calcAbcScore()

        default:
            return "Not yet implemented"
        }
    }

    // MARK: - Calculation Functions

    func calcAbcScore() -> String {
        guard let amsl = Double(abcAmsl), let crp = Double(abcCRP),
              let bun = Double(abcBUN), let asp = Double(abcAspartate),
              amsl >= 0, bun > 0, asp > 0 else {
            return "Enter valid values"
        }
        let logit = -11.23 + 0.99 * amsl
                   + 0.36 * log(max(bun, 1.0))
                   + 0.67 * log(max(asp, 1.0))
                   + 0.79 * log(max(crp, 0.1) + 0.1)
        let prob = 1.0 / (1.0 + exp(-logit)) * 100.0
        let risk = prob > 50 ? "High" : prob > 10 ? "Moderate" : "Low"
        return String(format: "30-Day Mortality: %.1f%% (%@)", prob, risk)
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("cda") {
                Section("CDAI (Crohn's Disease Activity Index)") {
                    Text("Score each 0-3 (stools/week 0-8):")
                    TextField("Bloody stools (0-6)", text: $cdaBleeding).keyboardType(.numberPad)
                    TextField("Abdominal symptoms (0-5)", text: $cdaMucus).keyboardType(.numberPad)
                    TextField("General well-being (0-3)", text: $cdaAbundance).keyboardType(.numberPad)
                    TextField("Stools per week (0-8)", text: $cdaBSymptoms).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("barrett") {
                Section("Barrett's Progression Risk") {
                    TextField("Years of Barrett's Esophagus", text: $barrettYears).keyboardType(.decimalPad)
                    Picker("Sex", selection: $barrettGender) {
                        Text("Male (0.33%/yr)").tag("0"); Text("Female (0.5%/yr)").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("das28") {
                Section("DAS28 (Rheumatoid Arthritis)") {
                    TextField("Swollen joints (0-28)", text: $das28Swollen).keyboardType(.decimalPad)
                    TextField("Tender joints (0-66)", text: $das28Tender).keyboardType(.decimalPad)
                    TextField("Patient global (0-100mm)", text: $das28Pain).keyboardType(.decimalPad)
                    TextField("CRP (mg/L)", text: $das28CRP).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("abc") {
                Section("ABC Score for GI Bleeding") {
                    TextField("AMSL score (0-8)", text: $abcAmsl).keyboardType(.decimalPad)
                    TextField("CRP (mg/dL)", text: $abcCRP).keyboardType(.decimalPad)
                    TextField("BUN (mg/dL)", text: $abcBUN).keyboardType(.decimalPad)
                    TextField("Aspartate aminotransferase (U/L)", text: $abcAspartate).keyboardType(.decimalPad)
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
