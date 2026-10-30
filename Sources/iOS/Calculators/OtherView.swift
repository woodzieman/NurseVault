import SwiftUI

struct OtherView: View {
    let calculator: CalculatorInfo

    var body: some View {
        if calculator.fileName.lowercased() == "gestationdate.htm" {
            GestationDateCalculator(calculator: calculator)
        } else if let spec = MedCalcSpecs.spec(for: calculator) {
            GenericCalculatorView(calculator: calculator, spec: spec)
        } else {
            Text("This calculator is not available yet.")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Gestation date (date-picker based; kept hand-written)

private struct GestationDateCalculator: View {
    let calculator: CalculatorInfo

    @State private var lmpDate = Date()
    @State private var usDate = Date()
    @State private var bpdText = ""
    @State private var hcText = ""
    @State private var crlText = ""

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        Form {
            Section("How to use") {
                Text("""
                Estimate the due date from the last menstrual period (LMP) and/or early ultrasound measurements.

                • LMP method: enter the first day of the last normal period; the due date is 280 days later.
                • Ultrasound methods: enter the scan date plus one or more biometry values in millimeters — biparietal diameter (BPD), head circumference (HC), and/or crown-rump length (CRL). Each measurement gives its own gestational age and due date; early CRL is the most accurate.
                """)
            }
            Section("Last menstrual period") {
                DatePicker("First day of last period", selection: $lmpDate, displayedComponents: .date)
            }
            Section("Ultrasound biometry (optional)") {
                DatePicker("Scan date", selection: $usDate, displayedComponents: .date)
                TextField("Biparietal diameter (mm)", text: $bpdText).decimalPadKeyboard()
                TextField("Head circumference (mm)", text: $hcText).decimalPadKeyboard()
                TextField("Crown-rump length (mm)", text: $crlText).decimalPadKeyboard()
            }
            Section("Result") { Text(result) }
        }
        .medCalcResultRecording(calculator: calculator, resultText: result)
    }

    private var result: String {
        let cal = Calendar.current
        var lines: [String] = []

        if let edc = cal.date(byAdding: .day, value: 280, to: lmpDate) {
            lines.append("By LMP (\(Self.dayFormatter.string(from: lmpDate))): due \(Self.dayFormatter.string(from: edc))")
        }

        func ultrasoundLine(_ label: String, _ text: String, days: Double?) -> String? {
            guard let value = Double(text), !text.isEmpty else { return nil }
            guard let d = days else { return "\(label): enter a valid measurement" }
            let edc = usDate.addingTimeInterval(-d * 86400 + 280 * 86400)
            return String(format: "By %@ (%.1f mm): %.1f weeks — due %@", label, value, d / 7, Self.dayFormatter.string(from: edc))
        }

        if let line = ultrasoundLine("BPD", bpdText, days: Double(bpdText).map { 2 * $0 + 44.2 }) { lines.append(line) }
        if let hc = Double(hcText), !hcText.isEmpty {
            let d = 7 * exp(1.854 + 0.010451 * hc - 0.000029919 * hc * hc + 0.000000043156 * hc * hc * hc)
            if let line = ultrasoundLine("HC", hcText, days: d) { lines.append(line) }
        }
        if let crl = Double(crlText), !crlText.isEmpty {
            let d = 7 * (5.2876 + 0.1584 * crl - 0.0007 * crl * crl)
            if let line = ultrasoundLine("CRL", crlText, days: d) { lines.append(line) }
        }

        return lines.isEmpty ? "Enter a last menstrual period date and/or ultrasound measurements." : lines.joined(separator: "\n")
    }
}
