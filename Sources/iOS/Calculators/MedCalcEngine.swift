import SwiftUI

// MARK: - Calculator input model

/// One labeled input control in a calculator form.
struct MedCalcInput: Identifiable, Sendable {
    enum Kind {
        /// Decimal text field; `unitHint` is shown as the placeholder (e.g., "kg").
        case number(unitHint: String)
        /// Segmented picker over fixed options; value = 0-based index into options.
        case choice(options: [String])
        /// Menu picker for scoring items (e.g., CIWA levels); value = 0-based index.
        case score(options: [String])
        /// Yes/No toggle; value = 1 or 0.
        case yesNo
    }

    let id: String
    let label: String
    let kind: Kind

    init(_ id: String, _ label: String, _ kind: Kind) {
        self.id = id
        self.label = label
        self.kind = kind
    }
}

// MARK: - Parsed values handed to compute closures

/// The current form state for one calculator. Empty or unparseable number fields are absent.
struct MedCalcValues: Sendable {
    private let numbers: [String: Double]
    private let selections: [String: Int]

    init(numbers: [String: Double], selections: [String: Int]) {
        self.numbers = numbers
        self.selections = selections
    }

    /// A numeric field value, or nil if the field is empty/unparseable.
    func number(_ id: String) -> Double? { numbers[id] }

    /// A choice index (0-based) or toggle value (1/0), or nil if unset.
    func selection(_ id: String) -> Int? { selections[id] }
}

// MARK: - Calculator spec

/// A complete calculator definition: how to use it, what to enter, and the math.
struct MedCalcSpec: Sendable {
    /// Matches `CalculatorInfo.fileName` (e.g., "mifflinstjeor.htm").
    let fileName: String
    /// Shown in the "How to use" section — how to conduct/interpret this test.
    let guide: String
    /// The equation as published in the source, shown under "Equation". Optional.
    var equation: String? = nil
    let inputs: [MedCalcInput]
    /// Returns result text, or "" when required values are missing.
    let compute: @Sendable (MedCalcValues) -> String

    init(fileName: String, guide: String, equation: String? = nil, inputs: [MedCalcInput], compute: @escaping @Sendable (MedCalcValues) -> String) {
        self.fileName = fileName
        self.guide = guide
        self.equation = equation
        self.inputs = inputs
        self.compute = compute
    }
}

// MARK: - Registry

/// Looks up calculator specs by catalog file name. Populated from the per-category spec files.
enum MedCalcSpecs {
    private static let all: [String: MedCalcSpec] = {
        var specs: [String: MedCalcSpec] = [:]
        func add(_ list: [MedCalcSpec]) {
            for spec in list { specs[spec.fileName.lowercased()] = spec }
        }

        add(cardiovascularCalculatorSpecs)
        add(criticalCareCalculatorSpecs)
        add(ebmStatisticsCalculatorSpecs)
        add(electrolytesAcidBaseCalculatorSpecs)
        add(endocrinologyCalculatorSpecs)
        add(gastroenterologyCalculatorSpecs)
        add(growthAnthropometricsCalculatorSpecs)
        add(hematologyCalculatorSpecs)
        add(hepaticCalculatorSpecs)
        add(infectiousDiseaseCalculatorSpecs)
        add(neonatologyCalculatorSpecs)
        add(mentalHealthCalculatorSpecs)
        add(neurologyCalculatorSpecs)
        add(otherCalculatorSpecs)
        add(oncologyCalculatorSpecs)
        add(pediatricsCalculatorSpecs)
        add(pharmacologyToxicologyCalculatorSpecs)
        add(pulmonaryCalculatorSpecs)
        add(renalCalculatorSpecs)
        add(rheumatologyCalculatorSpecs)
        add(sleepMedicineCalculatorSpecs)
        add(substanceUseCalculatorSpecs)
        add(unitConversionsCalculatorSpecs)
        add(urologyCalculatorSpecs)

        return specs
    }()

    static func spec(for calculator: CalculatorInfo) -> MedCalcSpec? {
        all[calculator.fileName.lowercased()]
    }
}

// MARK: - Generic calculator view

/// Renders any `MedCalcSpec`: a "How to use" guide, labeled inputs with units, and the result.
struct GenericCalculatorView: View {
    let calculator: CalculatorInfo
    let spec: MedCalcSpec

    @State private var textValues: [String: String] = [:]
    @State private var selectionValues: [String: Int] = [:]

    private var values: MedCalcValues {
        var numbers: [String: Double] = [:]
        for (id, raw) in textValues where !raw.isEmpty {
            if let value = Double(raw.trimmingCharacters(in: .whitespaces)) {
                numbers[id] = value
            }
        }
        return MedCalcValues(numbers: numbers, selections: selectionValues)
    }

    private var resultText: String { spec.compute(values) }

    var body: some View {
        Form {
            Section("How to use") {
                Text(spec.guide)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let equation = spec.equation {
                Section("Equation") {
                    Text(equation)
                        .font(.callout.monospaced())
                }
            }
            Section("Input") {
                ForEach(spec.inputs) { input in
                    inputView(input)
                }
            }
            Section("Result") {
                if resultText.isEmpty {
                    Text("Fill in the fields above to see the result.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(resultText)
                }
            }
        }
        .medCalcResultRecording(calculator: calculator, resultText: resultText)
    }

    @ViewBuilder
    private func inputView(_ input: MedCalcInput) -> some View {
        switch input.kind {
        case .number(let unitHint):
            VStack(alignment: .leading, spacing: 4) {
                Text(input.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField(unitHint, text: binding(for: input.id))
                    .decimalPadKeyboard()
            }
        case .choice(let options):
            VStack(alignment: .leading, spacing: 4) {
                Text(input.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker(input.label, selection: selectionBinding(for: input.id)) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
            }
        case .score(let options):
            VStack(alignment: .leading, spacing: 4) {
                Text(input.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("", selection: selectionBinding(for: input.id)) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index]).tag(index)
                    }
                }
                .labelsHidden()
            }
        case .yesNo:
            Toggle(isOn: toggleBinding(for: input.id)) {
                Text(input.label)
            }
        }
    }

    private func binding(for id: String) -> Binding<String> {
        Binding(
            get: { textValues[id] ?? "" },
            set: { textValues[id] = $0 }
        )
    }

    private func selectionBinding(for id: String) -> Binding<Int> {
        Binding(
            get: { selectionValues[id] ?? 0 },
            set: { selectionValues[id] = $0 }
        )
    }

    private func toggleBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { (selectionValues[id] ?? 0) == 1 },
            set: { selectionValues[id] = $0 ? 1 : 0 }
        )
    }
}

// MARK: - Coming soon placeholder

/// Shown for catalog calculators that don't have a spec yet.
struct MedCalcComingSoonView: View {
    let calculator: CalculatorInfo

    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "hammer.fill",
            description: Text("\(calculator.title) is on the way. It will appear here in an upcoming update.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
