import SwiftUI

struct SubstanceUseView: View {
    let calculator: CalculatorInfo

    var body: some View {
        if let spec = MedCalcSpecs.spec(for: calculator) {
            GenericCalculatorView(calculator: calculator, spec: spec)
        } else {
            Text("This calculator is not available yet.")
                .foregroundStyle(.secondary)
        }
    }
}
