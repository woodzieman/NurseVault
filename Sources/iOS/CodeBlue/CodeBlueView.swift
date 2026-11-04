import SwiftUI
import NurseVaultCore

/// Dedicated sidebar tab for the built-in resuscitation algorithms (ACLS + PALS).
/// Replaces the old approach of hiding these inside the "Code Blue" vault section —
/// now it's a first-class reference view alongside Drugs, Calculators, Merck, etc.
struct CodeBlueView: View {
    let algorithms = CodeBlueContent.algorithms
    
    var body: some View {
        NavigationStack {
            List {
                Section("Resuscitation Algorithms") {
                    ForEach(algorithms) { algorithm in
                        NavigationLink {
                            AlgorithmDetail(algorithm: algorithm)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(algorithm.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(algorithm.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Code Blue")
        }
    }
}

/// Detail view for a single ACLS or PALS algorithm.
private struct AlgorithmDetail: View {
    let algorithm: CodeBlueAlgorithm
    
    var body: some View {
        List {
            // Summary
            Section {
                Text(algorithm.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } header: {
                Label(algorithm.title, systemImage: "heart.fill")
                    .font(.headline)
            }
            
            // Steps
            Section("Algorithm Steps") {
                ForEach(Array(algorithm.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(step)
                            .font(.body)
                    }
                }
            }
            
            // Drug doses
            Section("Drug Doses") {
                ForEach(Array(algorithm.drugs.enumerated()), id: \.offset) { _, drug in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "pills")
                                .font(.caption)
                            Text(drug.name)
                                .fontWeight(.semibold)
                        }
                        Text("\(drug.dose) \(drug.route)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let note = drug.note, !note.isEmpty {
                            Text(note)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle(algorithm.title)
    }
}

// MARK: - Extension on CodeBlueContent to expose the algorithms

private extension CodeBlueContent {
    /// Returns the built-in algorithms for display.
    static var algorithms: [CodeBlueAlgorithm] {
        [adultACLS, pediatricPALS]
    }
}
