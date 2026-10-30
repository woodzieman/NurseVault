import SwiftUI
import NurseVaultCore

/// Watch presentation of the bundled laboratory reference: the plain-text
/// (paragraph) rendering of the same data the iOS app shows as tables.
/// The data is code in `NurseVaultCore`, so nothing is loaded from disk —
/// the feature is offline by construction.
struct WatchLabsView: View {
    private let reference = LabReferences.all[0]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(reference.sections) { section in
                    Text(section.title)
                        .font(.headline)
                    Text(section.text)
                        .font(.footnote)
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
                Text(reference.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(reference.title)
    }
}
