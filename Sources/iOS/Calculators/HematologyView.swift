import SwiftUI

struct HematologyView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo
    
    // MARK: - Absolute Counts State Properties
    @State private var absWbc = "7.0"
    @State private var absEosPct = "2.0"
    @State private var absLymPct = "35"
    @State private var absPnmPct = "60"
    
    // MARK: - Reticulocyte State Properties
    @State private var absRbc = "5.0"
    @State private var absRetPct = "1.0"
    @State private var absMatRets = "2.0"
    
    // MARK: - PLASMIC Score State Properties
    @State private var plasmicPlateletsLow = false
    @State private var plasmicHemolysis = false
    @State private var plasmicNoCancer = false
    @State private var plasmicNoTransplant = false
    @State private var plasmicMcvLow = false
    @State private var plasmicInrLow = false
    @State private var plasmicCreatLow = false
    
    // MARK: - HIT 4-T's Score State Properties
    @State private var hitThrombocytopenia: Int = 0
    @State private var hitTiming: Int = 0
    @State private var hitThrombosis: Int = 0
    @State private var hitOtherCauses: Int = 0
    
    // MARK: - Reticulocyte Production Index State Properties
    @State private var rpiHct = "40"
    @State private var rpiReticPct = "1.0"
    
    var body: some View {
        Form {
            Section("Inputs") { contentInput }
            Section("Result") { Text(calculationResult) }
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .medCalcResultRecording(calculator: calculator, resultText: calculationResult)
        .toolbar { Button("Close") { dismiss() } }
    }
    
    var contentInput: some View {
        Group {
            switch calculator.fileName.lowercased() {
            case "abseocount.htm":
                absoluteCountsInputView
            case "abslymphocnt.htm":
                absoluteCountsInputView
            case "absneutrophilecnt.htm":
                absoluteCountsInputView
            case "absreticcnt.htm":
                reticInputView
            case "plasmic.htm":
                plasmicInputView
            case "hit.htm":
                hitInputView
            case "reticprodindex.htm":
                rpiInputView
            default:
                Text("Input not yet implemented")
            }
        }
    }
    
    var calculationResult: String {
        switch calculator.fileName.lowercased() {
        case "abseocount.htm":
            return calcAbsoluteEosinophil()
        case "abslymphocnt.htm":
            return calcAbsoluteLymphocyte()
        case "absneutrophilecnt.htm":
            return calcAbsoluteNeutrophil()
        case "absreticcnt.htm":
            return calcAbsoluteReticulocyte()
        case "plasmic.htm":
            return calcPlasmic()
        case "hit.htm":
            return calcHIT4Ts()
        case "reticprodindex.htm":
            return calcReticulocyteProductionIndex()
        default:
            return "Not yet implemented"
        }
    }
    
    // MARK: - Calculation Functions
    
    func calcAbsoluteEosinophil() -> String {
        guard let wbc = Double(absWbc), let eosPct = Double(absEosPct),
              wbc > 0, eosPct >= 0 else { return "Enter valid values" }
        return String(format: "AEC: %.2f x 10³/µL", wbc * eosPct / 100.0)
    }
    
    func calcAbsoluteLymphocyte() -> String {
        guard let wbc = Double(absWbc), let lymPct = Double(absLymPct),
              wbc > 0, lymPct >= 0 else { return "Enter valid values" }
        return String(format: "ALC: %.2f x 10³/µL", wbc * lymPct / 100.0)
    }
    
    func calcAbsoluteNeutrophil() -> String {
        guard let wbc = Double(absWbc), let pnmPct = Double(absPnmPct),
              wbc > 0, pnmPct >= 0 else { return "Enter valid values" }
        return String(format: "ANC: %.2f x 10³/µL", wbc * pnmPct / 100.0)
    }
    
    func calcAbsoluteReticulocyte() -> String {
        guard let rbc = Double(absRbc), let retPct = Double(absRetPct),
              rbc > 0, retPct >= 0 else { return "Enter valid values" }
        let retCount = rbc * retPct / 100.0
        let retIndex = retPct * min(rbc / 45.0, 1.0) / max(1.0 + (Double(absMatRets) ?? 0), 1.0)
        return String(format: "Retic Count: %.4f x 10⁶/µL, Index: %.2f", retCount, retIndex)
    }
    
    func calcPlasmic() -> String {
        let score = ([plasmicPlateletsLow, plasmicHemolysis, plasmicNoCancer,
                      plasmicNoTransplant, plasmicMcvLow, plasmicInrLow,
                      plasmicCreatLow]).filter { $0 }.count
        let risk = score <= 4 ? "Low risk" : score == 5 ? "Intermediate risk" : "High risk"
        return String(format: "PLASMIC Score: %d/7 (%@)", score, risk)
    }
    
    func calcHIT4Ts() -> String {
        let score = hitThrombocytopenia + hitTiming + hitThrombosis + hitOtherCauses
        let probability = score <= 3 ? "Low probability" : score <= 5 ? "Intermediate probability" : "High probability"
        return String(format: "HIT 4-T's Score: %d/8 (%@)", score, probability)
    }
    
    func calcReticulocyteProductionIndex() -> String {
        guard let hct = Double(rpiHct), let reticPct = Double(rpiReticPct),
              hct > 0, reticPct >= 0 else {
            return "Enter valid values"
        }
        let maturation = hct >= 40 ? 1.0 : hct >= 30 ? 1.5 : hct >= 20 ? 2.0 : 2.5
        let rpi = (hct / 45.0) * (reticPct / maturation)
        return String(format: "RPI: %.2f (Maturation factor: %.1f)", rpi, maturation)
    }
    
    // MARK: - Input Views
    
    private var absoluteCountsInputView: some View {
        VStack(spacing: 12) {
            TextField("WBC (x 10³/µL)", text: $absWbc).keyboardType(.decimalPad)
            if calculator.fileName.lowercased().contains("eos") {
                TextField("Eosinophil percentage (%)", text: $absEosPct).keyboardType(.decimalPad)
            } else if calculator.fileName.lowercased().contains("lymph") {
                TextField("Lymphocyte percentage (%)", text: $absLymPct).keyboardType(.decimalPad)
            } else {
                TextField("Neutrophil percentage (%)", text: $absPnmPct).keyboardType(.decimalPad)
            }
        }
    }
    
    private var reticInputView: some View {
        VStack(spacing: 12) {
            TextField("RBC (x 10⁶/µL)", text: $absRbc).keyboardType(.decimalPad)
            TextField("Reticulocyte %", text: $absRetPct).keyboardType(.decimalPad)
            TextField("Maturation factor", text: $absMatRets).keyboardType(.decimalPad)
        }
    }
    
    private var plasmicInputView: some View {
        VStack(spacing: 10) {
            Toggle("Platelet count <30,000/µL", isOn: $plasmicPlateletsLow)
            Toggle("One or more indicators of hemolysis (Retic >2.5%, undetectable haptoglobin, or indirect bilirubin >2.0 mg/dL)", isOn: $plasmicHemolysis)
            Toggle("No active cancer in preceding year", isOn: $plasmicNoCancer)
            Toggle("No history of solid organ or hematopoietic stem cell transplant", isOn: $plasmicNoTransplant)
            Toggle("MCV <90 fL", isOn: $plasmicMcvLow)
            Toggle("INR <1.5", isOn: $plasmicInrLow)
            Toggle("Creatinine <2.0 mg/dL", isOn: $plasmicCreatLow)
        }
    }
    
    private var hitInputView: some View {
        VStack(spacing: 14) {
            Section("Thrombocytopenia") {
                Picker("Platelet fall pattern", selection: $hitThrombocytopenia) {
                    Text(">50% fall AND nadir ≥20,000/µL (2 pts)").tag(2)
                    Text("30-50% fall OR nadir 10-19,000/µL (1 pt)").tag(1)
                    Text("<30% fall OR nadir <10,000/µL (0 pts)").tag(0)
                }.pickerStyle(.segmented)
            }
            Section("Timing of platelet count fall") {
                Picker("Timing", selection: $hitTiming) {
                    Text("Clear onset days 5-10, or ≤1 day with prior heparin <30 days (2 pts)").tag(2)
                    Text("Consistent 5-10 but unclear, or >10, or ≤1 with prior heparin 30-100 days (1 pt)").tag(1)
                    Text("<4 days without recent heparin (0 pts)").tag(0)
                }.pickerStyle(.segmented)
            }
            Section("Thrombosis or other sequelae") {
                Picker("Thrombosis/necrosis/reaction", selection: $hitThrombosis) {
                    Text("Confirmed new thrombosis, skin necrosis, or acute systemic reaction (2 pts)").tag(2)
                    Text("Progressive/recurrent thrombosis, non-necrotizing skin lesions (1 pt)").tag(1)
                    Text("None (0 pts)").tag(0)
                }.pickerStyle(.segmented)
            }
            Section("Other causes for thrombocytopenia") {
                Picker("Other causes", selection: $hitOtherCauses) {
                    Text("None apparent (2 pts)").tag(2)
                    Text("Possible (1 pt)").tag(1)
                    Text("Definite (0 pts)").tag(0)
                }.pickerStyle(.segmented)
            }
        }
    }
    
    private var rpiInputView: some View {
        VStack(spacing: 12) {
            TextField("Hematocrit (%)", text: $rpiHct).keyboardType(.decimalPad)
            TextField("Reticulocyte percentage (%)", text: $rpiReticPct).keyboardType(.decimalPad)
        }
    }
}
