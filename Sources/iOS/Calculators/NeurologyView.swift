import SwiftUI

struct NeurologyView: View {
    let calculator: CalculatorInfo

    var body: some View {
        if let spec = MedCalcSpecs.spec(for: calculator) {
            GenericCalculatorView(calculator: calculator, spec: spec)
        } else {
            MedCalcComingSoonView(calculator: calculator)
        }
    }
}
