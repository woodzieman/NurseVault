import SwiftUI

/// Captures a calculator's live result into the shared store so widgets and the watch stay current.
///
/// Results in MedCalc are computed live from the inputs, so this records the result whenever it
/// changes (and once on appear). The store de-duplicates and debounces the widget reload.
struct MedCalcResultRecording: ViewModifier {
    let calculator: CalculatorInfo
    let resultText: String

    func body(content: Content) -> some View {
        content
            .onChange(of: resultText, initial: true) { _, newValue in
                ResultStore.shared.record(calculator: calculator, text: newValue)
            }
    }
}

extension View {
    /// Records `resultText` into the shared result store for this calculator.
    func medCalcResultRecording(calculator: CalculatorInfo, resultText: String) -> some View {
        modifier(MedCalcResultRecording(calculator: calculator, resultText: resultText))
    }
}
