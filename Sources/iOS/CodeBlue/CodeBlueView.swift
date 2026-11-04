import SwiftUI
import NurseVaultCore

/// Dedicated sidebar tab for the built-in resuscitation algorithms and
/// emergency reference. Shows all 7 algorithms organized by clinical scenario.
struct CodeBlueView: View {
    /// All Code Blue algorithms, organized into categories.
    private let categories = [
        Category(title: "Cardiac Arrest", algorithms: [CodeBlueContent.adultACLS, CodeBlueContent.pediatricPALS]),
        Category(title: "Airway & Breathing", algorithms: [CodeBlueContent.respiratoryDistress]),
        Category(title: "Arrhythmias", algorithms: [CodeBlueContent.tachycardia, CodeBlueContent.bradycardia]),
        Category(title: "Neurologic Emergencies", algorithms: [CodeBlueContent.acuteStroke]),
        Category(title: "Medical Emergencies", algorithms: [CodeBlueContent.sepsis])
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    Section(category.title) {
                        ForEach(category.algorithms) { algorithm in
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
            }
            .navigationTitle("Code Blue")
        }
    }
    
    /// Groups algorithms under a heading.
    private struct Category: Identifiable {
        let id = UUID()
        let title: String
        let algorithms: [CodeBlueAlgorithm]
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
