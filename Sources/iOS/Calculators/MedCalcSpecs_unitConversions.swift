import Foundation

/// Calculator specs for the unitConversions category.
let unitConversionsCalculatorSpecs: [MedCalcSpec] = {
    func conversion(fileName: String, guide: String, valueHint: String, units: [String], factors: [String: Double]) -> MedCalcSpec {
        MedCalcSpec(
            fileName: fileName,
            guide: guide,
            inputs: [
                MedCalcInput("value", "Value to convert", .number(unitHint: valueHint)),
                MedCalcInput("from", "From unit", .choice(options: units)),
                MedCalcInput("to", "To unit", .choice(options: units))
            ],
            compute: { v in
                guard let value = v.number("value"),
                      let fromIndex = v.selection("from"),
                      let toIndex = v.selection("to") else { return "" }
                let fromUnit = units[fromIndex]
                let toUnit = units[toIndex]
                guard let fromFactor = factors[fromUnit], let toFactor = factors[toUnit], toFactor != 0 else { return "" }
                let result = value * fromFactor / toFactor
                return String(format: "%.6g %@ = %.6g %@", value, fromUnit, result, toUnit)
            }
        )
    }

    return [
        conversion(
            fileName: "Basic.htm",
            guide: "Convert a measurement between common length units. Enter the value and choose the source and target units.",
            valueHint: "number",
            units: ["mm", "cm", "m", "km", "in", "ft", "yd", "mi"],
            factors: ["mm": 0.001, "cm": 0.01, "m": 1.0, "km": 1000.0, "in": 0.0254, "ft": 0.3048, "yd": 0.9144, "mi": 1609.34]
        ),
        conversion(
            fileName: "Length.htm",
            guide: "Convert a measurement between length units (metric and US customary). Enter the value and choose the source and target units.",
            valueHint: "number",
            units: ["in", "ft", "yd", "mi", "mm", "cm", "m", "km"],
            factors: ["in": 0.0254, "ft": 0.3048, "yd": 0.9144, "mi": 1609.34, "mm": 0.001, "cm": 0.01, "m": 1.0, "km": 1000.0]
        ),
        conversion(
            fileName: "Weight.htm",
            guide: "Convert a weight between units (metric and US customary). Enter the value and choose the source and target units.",
            valueHint: "number",
            units: ["lb", "oz", "kg", "g", "mg", "stone", "t"],
            factors: ["lb": 0.453592, "oz": 0.0283495, "kg": 1.0, "g": 0.001, "mg": 0.000001, "stone": 6.35029, "t": 1000.0]
        ),
        conversion(
            fileName: "Volume.htm",
            guide: "Convert a volume between units (US customary and metric). Enter the value and choose the source and target units.",
            valueHint: "number",
            units: ["fl oz", "cup", "pt", "gal", "ml", "l", "m3", "tbsp", "tsp"],
            factors: ["fl oz": 0.0295735, "cup": 0.236588, "pt": 0.473176, "gal": 3.78541, "ml": 0.001, "l": 1.0, "m3": 1000.0, "tbsp": 0.0147868, "tsp": 0.00492892]
        ),
        conversion(
            fileName: "Energy.htm",
            guide: "Convert an energy value between units (food calories, joules, and other common units). Enter the value and choose the source and target units.",
            valueHint: "number",
            units: ["kcal", "kJ", "cal", "J", "kWh", "BTU"],
            factors: ["kcal": 4.184, "kJ": 1.0, "cal": 4.184, "J": 1.0, "kWh": 3600.0, "BTU": 1.05506]
        ),
        MedCalcSpec(
            fileName: "Temperature.htm",
            guide: "Convert a temperature between Fahrenheit and Celsius. Enter the value and choose the direction of conversion.",
            inputs: [
                MedCalcInput("value", "Temperature", .number(unitHint: "°F or °C")),
                MedCalcInput("direction", "Direction", .choice(options: ["°F → °C", "°C → °F"]))
            ],
            compute: { v in
                guard let value = v.number("value"), let direction = v.selection("direction") else { return "" }
                if direction == 0 {
                    return String(format: "%.1f°F = %.1f°C", value, (value - 32.0) / 1.8)
                } else {
                    return String(format: "%.1f°C = %.1f°F", value, value * 1.8 + 32.0)
                }
            }
        ),
        MedCalcSpec(
            fileName: "Transferrin.htm",
            guide: """
            Transferrin saturation estimates how much of the transferrin protein is carrying iron — a key marker in evaluating iron deficiency and overload.

            • Serum iron (µg/dL) from a fasting morning sample
            • Total iron-binding capacity (TIBC, µg/dL) from the same panel

            Interpretation: <15% suggests iron deficiency; 15–45% is normal; >45% suggests iron overload.
            """,
            equation: "Transferrin Saturation (%) = Serum Iron / TIBC × 100",
            inputs: [
                MedCalcInput("iron", "Serum iron (µg/dL)", .number(unitHint: "µg/dL")),
                MedCalcInput("tci", "Total iron-binding capacity, TIBC (µg/dL)", .number(unitHint: "µg/dL"))
            ],
            compute: { v in
                guard let iron = v.number("iron"), let tci = v.number("tci"), iron > 0, tci > 0 else { return "" }
                let sat = iron / tci * 100.0
                let status = sat < 15 ? "Iron deficient" : sat <= 45 ? "Normal" : "Iron overload"
                return String(format: "Transferrin Saturation: %.1f%% (%@)", sat, status)
            }
        ),
        MedCalcSpec(
            fileName: "FractExcAmylase.htm",
            guide: """
            Fractional excretion of amylase (FE-amy) helps determine whether hyperamylasemia is pancreatic or extra-pancreatic in origin. Collect a simultaneous urine and plasma sample.

            • Urine amylase (U/L) and urine creatinine (mg/dL) from the same urine specimen
            • Plasma amylase (U/L) and plasma creatinine (mg/dL) from the same blood draw

            Interpretation: FE-amy > 5–6% suggests pancreatic origin of elevated amylase; lower values suggest extra-pancreatic sources.
            """,
            equation: "FE Amylase (%) = 100 × (Urine Amylase × Plasma Creatinine) / (Plasma Amylase × Urine Creatinine)",
            inputs: [
                MedCalcInput("urineAmylase", "Urine amylase (U/L)", .number(unitHint: "U/L")),
                MedCalcInput("plasmaCreat", "Plasma creatinine (mg/dL)", .number(unitHint: "mg/dL")),
                MedCalcInput("plasmaAmylase", "Plasma amylase (U/L)", .number(unitHint: "U/L")),
                MedCalcInput("urineCreat", "Urine creatinine (mg/dL)", .number(unitHint: "mg/dL"))
            ],
            compute: { v in
                guard let ua = v.number("urineAmylase"), let pc = v.number("plasmaCreat"),
                      let pa = v.number("plasmaAmylase"), let uc = v.number("urineCreat"),
                      ua > 0, pc > 0, pa > 0, uc > 0 else { return "" }
                let fe = 100 * (ua * pc) / (pa * uc)
                return String(format: "FE Amylase: %.2f%% (%@)", fe, fe > 5 ? "Pancreatic" : "Extra-pancreatic")
            }
        )
    ]
}()
