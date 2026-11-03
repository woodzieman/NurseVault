import SwiftUI
import NurseVaultCore

/// Watch presentation of the bundled laboratory reference.
///
/// The data is code in `NurseVaultCore`, so nothing is loaded from disk — the
/// feature is offline by construction. The watch uses a vertical, label/value
/// layout rather than the iOS `Grid` tables because watch screens are too
/// narrow for multi-column tables.
struct WatchLabsView: View {
    private let reference = LabReferences.all[0]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(reference.sections) { section in
                    Text(section.title)
                        .font(.headline)
                    Text(section.text)
                        .font(.footnote)
                }

                if !reference.valueGroups.isEmpty {
                    Text("Normal Lab Values")
                        .font(.headline)
                    ForEach(reference.valueGroups) { group in
                        Text(group.title)
                            .font(.subheadline)
                        ForEach(group.tests) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                    .font(.footnote.weight(.semibold))
                                Text(entry.range)
                                    .font(.footnote)
                                Text(entry.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                if !reference.panelTests.isEmpty {
                    Text("Commonly Used Panels")
                        .font(.headline)
                    Text(reference.panelsText)
                        .font(.footnote)
                }

                if !reference.tdmRows.isEmpty {
                    Text("Therapeutic Drug Monitoring")
                        .font(.headline)
                    Text(reference.tdmText)
                        .font(.footnote)
                }

                ForEach(reference.allSources) { source in
                    Text(source.text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(reference.title)
    }
}
