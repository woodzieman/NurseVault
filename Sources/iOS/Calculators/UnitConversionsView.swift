import SwiftUI

struct UnitConversionsView: View {
    @Environment(\.dismiss) var dismiss
    let calculator: CalculatorInfo

    @State private var basicValue = "1"
    @State private var basicFrom = "mm"
    @State private var basicTo = "cm"

    @State private var tempValue = "98.6"
    @State private var tempMode = "0"

    @State private var lengthValue = "1"
    @State private var lengthFrom = "in"
    @State private var lengthTo = "cm"

    @State private var weightValue = "150"
    @State private var weightFrom = "lb"
    @State private var weightTo = "kg"

    @State private var volumeValue = "1"
    @State private var volumeFrom = "fl oz"
    @State private var volumeTo = "ml"

    @State private var energyValue = "100"
    @State private var energyFrom = "kcal"
    @State private var energyTo = "kJ"

    @State private var flowValue = "1"
    @State private var flowFrom = "L/min"
    @State private var flowTo = "mL/s"

    @State private var transferrinIron = "80"
    @State private var transferrinTCI = "300"

    @State private var feAmylUrine = "500"
    @State private var feAmylSerum = "100"
    @State private var feAmylUCreat = "50"
    @State private var feAmylSCreat = "1.0"

    var result: String {
        switch calculator.fileName.lowercased() {
        case "basic.htm":
            guard let v = Double(basicValue) else { return "Enter a number" }
            let fromFactor: Double
            let toFactor: Double
            switch basicFrom {
            case "mm": fromFactor = 0.001
            case "cm": fromFactor = 0.01
            case "m": fromFactor = 1.0
            case "km": fromFactor = 1000.0
            case "in": fromFactor = 0.0254
            case "ft": fromFactor = 0.3048
            case "yd": fromFactor = 0.9144
            case "mi": fromFactor = 1609.34
            default: fromFactor = 1.0
            }
            switch basicTo {
            case "mm": toFactor = 0.001
            case "cm": toFactor = 0.01
            case "m": toFactor = 1.0
            case "km": toFactor = 1000.0
            case "in": toFactor = 0.0254
            case "ft": toFactor = 0.3048
            case "yd": toFactor = 0.9144
            case "mi": toFactor = 1609.34
            default: toFactor = 1.0
            }
            let meters = v * fromFactor
            let result = meters / toFactor
            return String(format: "%.6g %@ = %.6g %@", v, basicFrom, result, basicTo)

        case "temperature.htm":
            guard let v = Double(tempValue) else { return "Enter a number" }
            switch tempMode {
            case "0": // F to C
                let c = (v - 32.0) / 1.8
                return String(format: "%.1f°F = %.1f°C", v, c)
            case "1": // C to F
                let f = v * 1.8 + 32.0
                return String(format: "%.1f°C = %.1f°F", v, f)
            default:
                return "Select conversion direction"
            }

        case "length.htm":
            guard let v = Double(lengthValue) else { return "Enter a number" }
            let factors: [String: Double] = ["in": 0.0254, "ft": 0.3048, "yd": 0.9144, "mi": 1609.34, "mm": 0.001, "cm": 0.01, "m": 1.0, "km": 1000.0]
            let fromF = factors[lengthFrom] ?? 1.0
            let toF = factors[lengthTo] ?? 1.0
            let result = v * fromF / toF
            return String(format: "%.6g %@ = %.6g %@", v, lengthFrom, result, lengthTo)

        case "weight.htm":
            guard let v = Double(weightValue) else { return "Enter a number" }
            let factors: [String: Double] = ["lb": 0.453592, "oz": 0.0283495, "kg": 1.0, "g": 0.001, "mg": 0.000001, "stone": 6.35029, "t": 1000.0]
            let fromF = factors[weightFrom] ?? 1.0
            let toF = factors[weightTo] ?? 1.0
            let result = v * fromF / toF
            return String(format: "%.6g %@ = %.6g %@", v, weightFrom, result, weightTo)

        case "volume.htm":
            guard let v = Double(volumeValue) else { return "Enter a number" }
            let factors: [String: Double] = ["fl oz": 0.0295735, "cup": 0.236588, "pt": 0.473176, "gal": 3.78541, "ml": 0.001, "l": 1.0, "m3": 1000.0, "tbsp": 0.0147868, "tsp": 0.00492892]
            let fromF = factors[volumeFrom] ?? 1.0
            let toF = factors[volumeTo] ?? 1.0
            let result = v * fromF / toF
            return String(format: "%.6g %@ = %.6g %@", v, volumeFrom, result, volumeTo)

        case "energy.htm":
            guard let v = Double(energyValue) else { return "Enter a number" }
            let factors: [String: Double] = ["kcal": 4.184, "kJ": 1.0, "cal": 4.184, "J": 1.0, "kWh": 3600.0, "BTU": 1.05506]
            let fromF = factors[energyFrom] ?? 1.0
            let toF = factors[energyTo] ?? 1.0
            let result = v * fromF / toF
            return String(format: "%.6g %@ = %.6g %@", v, energyFrom, result, energyTo)

        case "flow.htm":
            guard let v = Double(flowValue) else { return "Enter a number" }
            let factors: [String: Double] = ["L/min": 1.0, "mL/s": 0.016667, "mL/min": 0.001, "L/s": 0.001, "dL/min": 0.1]
            let fromF = factors[flowFrom] ?? 1.0
            let toF = factors[flowTo] ?? 1.0
            let result = v * fromF / toF
            return String(format: "%.6g %@ = %.6g %@", v, flowFrom, result, flowTo)

        case "transferrin.htm":
            guard let iron = Double(transferrinIron), let tci = Double(transferrinTCI),
                  iron > 0, tci > 0 else {
                return "Enter valid values"
            }
            let sat = iron / tci * 100.0
            let status = sat < 15 ? "Iron deficient" : sat < 45 ? "Normal" : sat > 45 ? "Iron overload" : "Normal"
            return String(format: "Transferrin Saturation: %.1f%% (%@)", sat, status)

        case "fractexcmylase.htm":
            guard let ua = Double(feAmylUrine), let sa = Double(feAmylSerum),
                  let uc = Double(feAmylUCreat), let sc = Double(feAmylSCreat),
                  ua > 0, sa > 0, uc > 0, sc > 0 else {
                return "Enter valid values"
            }
            let fe = (ua / sa) / (uc / sc) * 100.0
            return String(format: "FE Amylase: %.2f%% (%@)", fe, fe > 5 ? "Pancreatic" : "Extra-pancreatic")

        default:
            return "Not yet implemented"
        }
    }

    var body: some View {
        Form {
            if calculator.fileName.lowercased().contains("basic") {
                Section("Basic Unit Conversion") {
                    TextField("Value", text: $basicValue).keyboardType(.decimalPad)
                    Picker("From", selection: $basicFrom) {
                        ForEach(["mm", "cm", "m", "km", "in", "ft", "yd", "mi"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    Picker("To", selection: $basicTo) {
                        ForEach(["mm", "cm", "m", "km", "in", "ft", "yd", "mi"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("temperature") {
                Section("Temperature Conversion") {
                    TextField("Temperature", text: $tempValue).keyboardType(.decimalPad)
                    Picker("Direction", selection: $tempMode) {
                        Text("°F → °C").tag("0")
                        Text("°C → °F").tag("1")
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("length") {
                Section("Length Conversion") {
                    TextField("Value", text: $lengthValue).keyboardType(.decimalPad)
                    Picker("From", selection: $lengthFrom) {
                        ForEach(["in", "ft", "yd", "mi", "mm", "cm", "m", "km"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    Picker("To", selection: $lengthTo) {
                        ForEach(["in", "ft", "yd", "mi", "mm", "cm", "m", "km"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("weight") {
                Section("Weight Conversion") {
                    TextField("Value", text: $weightValue).keyboardType(.decimalPad)
                    Picker("From", selection: $weightFrom) {
                        ForEach(["lb", "oz", "kg", "g", "mg", "stone", "t"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    Picker("To", selection: $weightTo) {
                        ForEach(["lb", "oz", "kg", "g", "mg", "stone", "t"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("volume") {
                Section("Volume Conversion") {
                    TextField("Value", text: $volumeValue).keyboardType(.decimalPad)
                    Picker("From", selection: $volumeFrom) {
                        ForEach(["fl oz", "cup", "pt", "gal", "ml", "l", "m3", "tbsp", "tsp"], id: \.self) { Text($0) }
                    }.pickerStyle(.wheel)
                    Picker("To", selection: $volumeTo) {
                        ForEach(["fl oz", "cup", "pt", "gal", "ml", "l", "m3", "tbsp", "tsp"], id: \.self) { Text($0) }
                    }.pickerStyle(.wheel)
                }
            }
            if calculator.fileName.lowercased().contains("energy") {
                Section("Energy Conversion") {
                    TextField("Value", text: $energyValue).keyboardType(.decimalPad)
                    Picker("From", selection: $energyFrom) {
                        ForEach(["kcal", "kJ", "cal", "J", "kWh", "BTU"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    Picker("To", selection: $energyTo) {
                        ForEach(["kcal", "kJ", "cal", "J", "kWh", "BTU"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("flow") {
                Section("Flow Rate Conversion") {
                    TextField("Value", text: $flowValue).keyboardType(.decimalPad)
                    Picker("From", selection: $flowFrom) {
                        ForEach(["L/min", "mL/s", "mL/min", "L/s", "dL/min"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    Picker("To", selection: $flowTo) {
                        ForEach(["L/min", "mL/s", "mL/min", "L/s", "dL/min"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                }
            }
            if calculator.fileName.lowercased().contains("transferrin") {
                Section("Transferrin Saturation") {
                    TextField("Serum Iron (µg/dL)", text: $transferrinIron).keyboardType(.decimalPad)
                    TextField("Total Iron Binding Capacity (µg/dL)", text: $transferrinTCI).keyboardType(.decimalPad)
                }
            }
            if calculator.fileName.lowercased().contains("fract") || calculator.fileName.lowercased().contains("amylase") {
                Section("Fractional Excretion of Amylase") {
                    TextField("Urine Amylase (U/L)", text: $feAmylUrine).keyboardType(.decimalPad)
                    TextField("Serum Amylase (U/L)", text: $feAmylSerum).keyboardType(.decimalPad)
                    TextField("Urine Creatinine (mg/dL)", text: $feAmylUCreat).keyboardType(.decimalPad)
                    TextField("Serum Creatinine (mg/dL)", text: $feAmylSCreat).keyboardType(.decimalPad)
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
