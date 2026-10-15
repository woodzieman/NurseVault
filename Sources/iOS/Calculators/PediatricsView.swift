import SwiftUI

struct PediatricsView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var bpAge = "10"
    @State private var bpH = "140"
    @State private var bpS = "110"
    @State private var bpGrlAge = "10"
    @State private var bpGrlH = "140"
    @State private var bpGrlS = "105"
    @State private var bp2017Age = "5"
    @State private var bp2017H = "110"

    @State private var cwcAge = "5"
    @State private var cwcW = "18"
    @State private var cwcH = "110"
    @State private var cwcGrlAge = "5"
    @State private var cwcGrlW = "17"
    @State private var cwcGrlH = "108"

    @State private var wfaAge = "2"
    @State private var wfaW = "10"

    @State private var whcAge = "6"
    @State private var whcH = "50"

    @State private var wflAge = "1"
    @State private var wflL = "75"
    @State private var wflW = "8"

    @State private var wfaLenAge = "12"
    @State private var wfaLenL = "75"

    @State private var maintW = "20"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "bloodpressurepercentboys.htm":
            guard let a = Double(bpAge), let h = Double(bpH), let s = Double(bpS),
                  a > 0, h > 0, s > 0 else {
                return "Enter valid values"
            }
            let z = (s - (100.0 + 2.0 * (a / 10.0))) / 10.0
            return String(format: "BP Percentile (Boys): ~%gth", max(0, min(99, Int(normalCDF(z) * 100))))

        case "bloodpressurepercentgirls.htm":
            guard let a = Double(bpGrlAge), let h = Double(bpGrlH), let s = Double(bpGrlS),
                  a > 0, h > 0, s > 0 else {
                return "Enter valid values"
            }
            let z = (s - (95.0 + 1.8 * (a / 10.0))) / 9.5
            return String(format: "BP Percentile (Girls): ~%gth", max(0, min(99, Int(normalCDF(z) * 100))))

        case "bloodpressurepercent2017.htm":
            guard let a = Double(bp2017Age), let h = Double(bp2017H), let s = Double(bpS),
                  a > 0, h > 0, s > 0 else {
                return "Enter valid values"
            }
            let z = (s - (105.0 + 1.5 * (a / 10.0))) / 10.0
            return String(format: "2017 BP Percentile: ~%gth", max(0, min(99, Int(normalCDF(z) * 100))))

        case "cwcweightforageboys.htm":
            guard let a = Double(cwcAge), let w = Double(cwcW), a > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "Weight-for-age (Boys): z=%.2f", (w - 12.0 * max(1.0, a / 10.0)) / 3.0)

        case "cwcweightforagegirls.htm":
            guard let a = Double(cwcGrlAge), let w = Double(cwcGrlW), a > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "Weight-for-age (Girls): z=%.2f", (w - 11.8 * max(1.0, a / 10.0)) / 2.8)

        case "cwcweightforheightboys.htm":
            guard let h = Double(cwcH), let w = Double(cwcW), h > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "Wt/Ht (Boys): z=%.2f", (w - (h - 100.0) * 0.2) / 3.0)

        case "cwcweightforheightgirls.htm":
            guard let h = Double(cwcGrlH), let w = Double(cwcGrlW), h > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "Wt/Ht (Girls): z=%.2f", (w - (h - 105.0) * 0.18) / 2.8)

        case "cwcheadcircumferenceboys.htm":
            guard let a = Double(cwcAge), let hc = Double(whcH), a > 0 else {
                return "Enter valid values"
            }
            return String(format: "Head Circ (Boys): z=%.2f", (hc - (46.0 + 1.5 * min(1.0, a / 5.0))) / 1.5)

        case "cwcheadcircumferencegirls.htm":
            guard let a = Double(cwcGrlAge), let hc = Double(whcH), a > 0 else {
                return "Enter valid values"
            }
            return String(format: "Head Circ (Girls): z=%.2f", (hc - (45.5 + 1.4 * min(1.0, a / 5.0))) / 1.4)

        case "cwcweightforage2017.htm":
            guard let a = Double(cwcAge), let w = Double(cwcW), a > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "2017 Wt-for-age: z=%.2f", (w - 12.0) / 3.0)

        case "whoheadcircumference.htm":
            guard let a = Double(whcAge), let hc = Double(whcH), a > 0 else {
                return "Enter valid values"
            }
            return String(format: "WHO Head Circ: z=%.2f", (hc - (47.1 - 0.1 * a)) / 1.6)

        case "whoweightforage.htm":
            guard let a = Double(wfaAge), let w = Double(wfaW), a > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "WHO Wt-for-age: z=%.2f", (w - 12.0) / 3.0)

        case "whoweightforlength.htm":
            guard let l = Double(wflL), let w = Double(wflW), l > 0, w > 0 else {
                return "Enter valid values"
            }
            return String(format: "Wt-for-length: z=%.2f", (w - (l - 50.0) * 0.35) / 2.5)

        case "wholengthforage.htm":
            guard let a = Double(wfaLenAge), let l = Double(wfaLenL), a > 0, l > 0 else {
                return "Enter valid values"
            }
            return String(format: "Length-for-age: z=%.2f", (l - 50.0 - a * 2.5) / 2.0)

        case "maintenancefluid.htm":
            guard let w = Double(maintW), w > 0 else {
                return "Enter weight"
            }
            let f: Double
            if w <= 10 {
                f = w * 100.0
            } else if w <= 20 {
                f = 1000.0 + (w - 10.0) * 50.0
            } else {
                f = 1500.0 + (w - 20.0) * 20.0
            }
            return String(format: "Holliday-Segar: %.0f mL/day (%.0f mL/hr)", f, f / 24.0)

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("bloodpressure") {
                Section("Blood Pressure Percentile") {
                    TextField("Age (years)", text: $bpAge).keyboardType(.decimalPad)
                    TextField("Height (cm)", text: $bpH).keyboardType(.decimalPad)
                    TextField("Systolic BP (mmHg)", text: $bpS).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("cwc") || calculator.fileName.lowercased().contains("growth") {
                Section("Growth Charts (CDC)") {
                    TextField("Age (years)", text: $cwcAge).keyboardType(.decimalPad)
                    TextField("Height/Length (cm)", text: $cwcH).keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $cwcW).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("who") {
                Section("WHO Growth Charts") {
                    TextField("Age (months/years)", text: $wfaAge).keyboardType(.decimalPad)
                    TextField("Length/Height (cm)", text: $wflL).keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $wfaW).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("maintenance") {
                Section("Maintenance Fluid (Holliday-Segar)") {
                    TextField("Weight (kg)", text: $maintW).keyboardType(.decimalPad)
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
