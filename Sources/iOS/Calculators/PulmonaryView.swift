import SwiftUI

struct PulmonaryView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var bodeFEV1 = "50"
    @State private var bodeAge = "60"
    @State private var bodeBMI = "25"
    @State private var bodeMRC = "2"

    @State private var dlcoP = "25"
    @State private var dlcoA = "30"
    @State private var dlcoHgb = "14"

    @State private var lungTV = "500"
    @State private var lungRR = "12"
    @State private var lungFRC = "2.5"

    @State private var peakH = "170"
    @State private var peakAge = "30"
    @State private var peakG = "0"

    @State private var pftFEV1 = "70"
    @State private var pftFVC = "85"
    @State private var pftAge = "50"
    @State private var pftH = "170"
    @State private var pftG = "0"

    @State private var nodAge = "65"
    @State private var nodSmkPkg = "30"
    @State private var nodHx = "1"

    @State private var flowFVC = "3.5"
    @State private var flowFEV1 = "2.8"

    // MARK: - A-a Gradient State Properties
    @State private var aagPao2 = "95"
    @State private var aagPaco2 = "40"
    @State private var aagFio2 = "0.21"

    // MARK: - Arterial Blood Gas State Properties
    @State private var abgPh = "7.40"
    @State private var abgPco2 = "40"
    @State private var abgHco3 = "24"

    // MARK: - Oxygen Delivery State Properties
    @State private var oxyFio2 = "0.21"
    @State private var oxyHgb = "14"
    @State private var oxyPao2 = "95"

    // MARK: - PaO2/FiO2 Ratio State Properties
    @State private var paoFi2PaO2 = "100"
    @State private var paoFi2FiO2 = "0.21"

    // MARK: - Pneumothorax State Properties
    @State private var pneumHemithorax = "30"
    @State private var pneumAir = "5"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "bode.htm":
            guard let fev1 = Double(bodeFEV1), let age = Double(bodeAge),
                  let bmi = Double(bodeBMI), let mrc = Double(bodeMRC),
                  fev1 > 0, age > 0, bmi > 0 else {
                return "Enter valid values"
            }
            let score = fev1 / 100.0 * 0.5 + max(0.0, (1.1 - bmi) * 0.25)
                       + max(0.0, (mrc - 1.0)) * 0.2 + max(0.0, (age - 70.0) / 10.0) * 0.2
            return String(format: "BODE Index: %.1f (4-yr survival: %@)", score, score < 2 ? ">90%" : score < 4 ? "60-90%" : "<60%")

        case "dlco_anemia.htm":
            guard let p = Double(dlcoP), let a = Double(dlcoA), let h = Double(dlcoHgb),
                  p > 0, a > 0, h > 0 else {
                return "Enter valid values"
            }
            let adj = p * (1.0 + 0.0136 * (14.0 - h) + 0.0004 * (a - 12.0))
            return String(format: "DLCO Corrected: %.0f mL/min (for anemia)", adj)

        case "lungvolumes.htm":
            guard let tv = Double(lungTV), let rr = Double(lungRR), let frc = Double(lungFRC),
                  tv > 0, rr > 0, frc > 0 else {
                return "Enter valid values"
            }
            let va = frc * 1.25 - tv
            return String(format: "Alveolar Volume: %.2f L", max(0.0, va))

        case "peakexpflow.htm":
            guard let h = Double(peakH), let age = Double(peakAge), h > 0, age > 0 else {
                return "Enter valid values"
            }
            let peak: Double
            if peakG == "0" {
                peak = (120.0 + 2.5 * (h - 150.0)) / (1.0 + (age - 20.0) / 10.0)
            } else {
                peak = (100.0 + 2.0 * (h - 150.0)) / (1.0 + (age - 20.0) / 10.0)
            }
            return String(format: "Predicted PEF: %.0f L/min (%@)", peak, peakG == "0" ? "Male" : "Female")

        case "pft_gli.htm":
            guard let fev1 = Double(pftFEV1), let fvc = Double(pftFVC),
                  let age = Double(pftAge), let h = Double(pftH),
                  fev1 > 0, fvc > 0, age > 0, h > 0 else {
                return "Enter valid values"
            }
            let ratio = fev1 / fvc * 100.0
            let cat = ratio < 70.0 ? "Obstructive" : ratio < 80.0 ? "Borderline" : "Normal"
            return String(format: "FEV1/FVC: %.1f%% (%@)", ratio, cat)

        case "solitarypulmnn.htm":
            guard let age = Double(nodAge), let smk = Double(nodSmkPkg),
                  let h = Double(nodHx), age > 0, smk > 0 else {
                return "Enter valid values"
            }
            let score = age * 0.1 + smk * 0.05 + h * 0.3
            let rec = score > 0.65 ? "High - biopsy" : score > 0.15 ? "Intermediate - CT" : "Low - monitor"
            return String(format: "Nodule Risk: %.2f (%@)", score, rec)

        case "flow.htm":
            guard let fvc = Double(flowFVC), let fev1 = Double(flowFEV1),
                  fvc > 0, fev1 > 0 else {
                return "Enter valid values"
            }
            let ratio = fev1 / fvc * 100.0
            let cat = ratio < 70.0 ? "Obstructive" : ratio < 80.0 ? "Borderline" : "Normal"
            return String(format: "FEV1/FVC: %.1f%% (%@)", ratio, cat)

        case "aagradient.htm":
            return calcAaGradient()

        case "arterialbloodgas.htm":
            return calcAbg()

        case "oxygen.htm":
            return calcOxygenDelivery()

        case "pao2_fio2ratio.htm":
            return calcPaoFi2Ratio()

        case "pneumothorax.htm":
            return calcPneumothorax()

        default:
            return "Not yet implemented"
        }
    }

    // MARK: - Calculation Functions

    func calcAaGradient() -> String {
        guard let pao2 = Double(aagPao2), let paco2 = Double(aagPaco2),
              let fio2 = Double(aagFio2), pao2 > 0, paco2 > 0, fio2 > 0 else {
            return "Enter valid values"
        }
        let paAlv = fio2 * (760.0 - 47.0) - (paco2 / 0.8)
        let gradient = paAlv - pao2
        let classification = gradient > 15 ? "Elevated" : "Normal"
        return String(format: "A-a Gradient: %.1f mmHg (%@)", gradient, classification)
    }

    func calcAbg() -> String {
        guard let ph = Double(abgPh), let pco2 = Double(abgPco2),
              let hco3 = Double(abgHco3), ph > 0, pco2 > 0, hco3 > 0 else {
            return "Enter valid values"
        }
        var result = ""
        if ph < 7.35 { result += "Acidemia\n" } else if ph > 7.45 { result += "Alkalemia\n" }
        if pco2 > 45 { result += "Resp acidosis\n" } else if pco2 < 35 { result += "Resp alkalosis\n" }
        if hco3 < 22 { result += "Metabolic acidosis" } else if hco3 > 26 { result += "Metabolic alkalosis" }
        else { result += "Normal metabolic" }
        return result.isEmpty ? "Normal ABG" : result
    }

    func calcOxygenDelivery() -> String {
        guard let fio2 = Double(oxyFio2), let hgb = Double(oxyHgb),
              let pao2 = Double(oxyPao2), fio2 > 0, hgb > 0, pao2 > 0 else {
            return "Enter valid values"
        }
        let caO2 = (1.34 * hgb * fio2) + (0.003 * pao2)
        return String(format: "CaO2: %.2f mL/dL", caO2)
    }

    func calcPaoFi2Ratio() -> String {
        guard let paO2 = Double(paoFi2PaO2), let fio2 = Double(paoFi2FiO2),
              paO2 > 0, fio2 > 0 else { return "Enter valid values" }
        let ratio = paO2 / fio2
        let ards = ratio < 200 ? "Moderate ARDS" : ratio < 300 ? "Mild ARDS" : "No ARDS"
        return String(format: "PaO2/FiO2: %.0f (%@)", ratio, ards)
    }

    func calcPneumothorax() -> String {
        guard let hemi = Double(pneumHemithorax), hemi > 0 else { return "Enter valid values" }
        let degree = (Double(pneumAir) ?? 0) / hemi * 100.0
        let size = degree < 20 ? "Small" : degree < 50 ? "Moderate" : "Large"
        return String(format: "Pneumothorax: %.1f%% (%@)", degree, size)
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("bode") {
                Section("BODE Index") {
                    TextField("FEV1 (% predicted)", text: $bodeFEV1).keyboardType(.decimalPad)
                    TextField("Age (years)", text: $bodeAge).keyboardType(.decimalPad)
                    TextField("BMI (kg/m²)", text: $bodeBMI).keyboardType(.decimalPad)
                    TextField("MRC Dyspnea (0-4)", text: $bodeMRC).keyboardType(.numberPad)
                }
            }
            if calculator.fileName.lowercased().contains("dlco") {
                Section("DLCO (Anemia Correction)") {
                    TextField("Measured DLCO (mL/min)", text: $dlcoP).keyboardType(.decimalPad)
                    TextField("Alveolar Volume (L)", text: $dlcoA).keyboardType(.decimalPad)
                    TextField("Hemoglobin (g/dL)", text: $dlcoHgb).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("lungvol") {
                Section("Lung Volumes") {
                    TextField("Tidal Volume (L)", text: $lungTV).keyboardType(.decimalPad)
                    TextField("Respiratory Rate (/min)", text: $lungRR).keyboardType(.decimalPad)
                    TextField("FRC (L)", text: $lungFRC).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("peak") {
                Section("Peak Expiratory Flow") {
                    TextField("Height (cm)", text: $peakH).keyboardType(.decimalPad)
                    TextField("Age (years)", text: $peakAge).keyboardType(.decimalPad)
                    Picker("Sex", selection: $peakG) {
                        Text("Male").tag("0"); Text("Female").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("pft") || calculator.fileName.lowercased().contains("flow") {
                Section("Spirometry (GLI)") {
                    TextField("FEV1 (% predicted)", text: $pftFEV1).keyboardType(.decimalPad)
                    TextField("FVC (% predicted)", text: $pftFVC).keyboardType(.decimalPad)
                    TextField("Age (years)", text: $pftAge).keyboardType(.decimalPad)
                    TextField("Height (cm)", text: $pftH).keyboardType(.decimalPad)
                    Picker("Sex", selection: $pftG) {
                        Text("Male").tag("0"); Text("Female").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("nodule") || calculator.fileName.lowercased().contains("solitary") {
                Section("Solitary Pulmonary Nodule") {
                    TextField("Age (years)", text: $nodAge).keyboardType(.decimalPad)
                    TextField("Pack-years", text: $nodSmkPkg).keyboardType(.decimalPad)
                    Picker("Smoking History", selection: $nodHx) {
                        Text("Never").tag("0"); Text("Former").tag("1"); Text("Current").tag("2")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("aagradient") || calculator.fileName.lowercased().contains("a-a gradient") {
                Section("A-a Gradient") {
                    TextField("PaO2 (mmHg)", text: $aagPao2).keyboardType(.decimalPad)
                    TextField("PaCO2 (mmHg)", text: $aagPaco2).keyboardType(.decimalPad)
                    TextField("FiO2 (fraction)", text: $aagFio2).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("arterialbloodgas") || calculator.fileName.lowercased().contains("abg") {
                Section("Arterial Blood Gas Interpretation") {
                    TextField("pH", text: $abgPh).keyboardType(.decimalPad)
                    TextField("pCO2 (mmHg)", text: $abgPco2).keyboardType(.decimalPad)
                    TextField("HCO3 (mmol/L)", text: $abgHco3).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("oxygen") {
                Section("Oxygen Delivery Units Conversions") {
                    TextField("FiO2 (fraction)", text: $oxyFio2).keyboardType(.decimalPad)
                    TextField("Hemoglobin (g/dL)", text: $oxyHgb).keyboardType(.decimalPad)
                    TextField("PaO2 (mmHg)", text: $oxyPao2).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("pao2") || calculator.fileName.lowercased().contains("fio2") {
                Section("PaO2/FiO2 Ratio") {
                    TextField("PaO2 (mmHg)", text: $paoFi2PaO2).keyboardType(.decimalPad)
                    TextField("FiO2 (fraction)", text: $paoFi2FiO2).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("pneumothorax") {
                Section("Pneumothorax Degree of Collapse") {
                    TextField("Hemithorax depth (cm)", text: $pneumHemithorax).keyboardType(.decimalPad)
                    TextField("Air space depth (cm)", text: $pneumAir).keyboardType(.decimalPad)
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
