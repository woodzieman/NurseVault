import SwiftUI

struct ObstetricsView: View {
    let calculator: CalculatorInfo
    
    @State private var lmp = Date()
    @State private var resultDate: Date?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if calculator.id == "NaegelesRule" {
                naegelesRuleUI
            } else {
                dueDateUI
            }
            
            Spacer()
        }
        .padding()
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Naegele's Rule UI
    private var naegelesRuleUI: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Naegele's Rule")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Formula: LMP + 7 days - 3 months + 1 year")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            DatePicker("Last Menstrual Period (LMP)", selection: $lmp, displayedComponents: .date)
                .datePickerStyle(.graphical)

            Button(action: calculateNaegeles) {
                Text("Calculate Due Date")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let result = resultDate {
                resultDisplay(date: result)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
    }

    // MARK: - Due Date UI
    private var dueDateUI: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Due Date Calculator")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Estimate the expected date of delivery (EDD).")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            DatePicker("Last Menstrual Period (LMP)", selection: $lmp, displayedComponents: .date)
                .datePickerStyle(.graphical)

            Button(action: calculateDueDate) {
                Text("Calculate EDD")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let result = resultDate {
                resultDisplay(date: result)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
    }

    private func resultDisplay(date: Date) -> some View {
        VStack(spacing: 8) {
            Text("Estimated Due Date:")
                .font(.headline)
            Text(date, style: .date)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
    }

    private func calculateNaegeles() {
        errorMessage = nil
        let calendar = Calendar.current
        
        // Naegele's Rule: LMP + 7 days - 3 months + 1 year
        if let datePlus7 = calendar.date(byAdding: .day, value: 7, to: lmp),
           let dateMinus3Months = calendar.date(byAdding: .month, value: -3, to: datePlus7),
           let finalDate = calendar.date(byAdding: .year, value: 1, to: dateMinus3Months) {
            resultDate = finalDate
        } else {
            errorMessage = "Calculation error. Please try again."
        }
    }

    private func calculateDueDate() {
        errorMessage = nil
        // Standard EDD is generally the same as Naegele's for 28-day cycles
        calculateNaegeles()
    }
}
