import SwiftUI
import NurseVaultCore

/// Labs sidebar entry: the bundled laboratory reference data, presented as
/// tables on iOS. (The watch app renders the same data as plain text.)
struct LabsView: View {
    var reference: LabReference = LabReferences.all[0]

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    ForEach(reference.sections) { section in
                        NavigationLink(section.title) {
                            LabAboutView(section: section)
                        }
                    }
                }
                if !reference.panelTests.isEmpty {
                    Section {
                        NavigationLink("Commonly Used Panels") {
                            LabPanelsView(reference: reference)
                        }
                    } footer: {
                        Text("Which tests are in each standardized panel.")
                    }
                }
                if !reference.tdmRows.isEmpty {
                    Section {
                        NavigationLink("Therapeutic Drug Monitoring") {
                            LabTDMView(reference: reference)
                        }
                    } footer: {
                        Text("Target and critical levels for narrow-therapeutic-index drugs.")
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reference.source)
                        if let url = URL(string: reference.sourceURL) {
                            Link("View source", destination: url)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(reference.title)
        }
    }
}

/// One interpretive text section of a lab reference.
private struct LabAboutView: View {
    let section: LabReferenceSection

    var body: some View {
        ScrollView {
            Text(section.text)
                .padding()
        }
        .navigationTitle(section.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The "commonly used panels" table: one row per test, a checkmark in each
/// panel column that includes it.
private struct LabPanelsView: View {
    let reference: LabReference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Grid(horizontalSpacing: 10, verticalSpacing: 6) {
                    GridRow {
                        Text("Test")
                            .font(.footnote.weight(.semibold))
                            .gridColumnAlignment(.leading)
                        ForEach(reference.panelColumns, id: \.self) { column in
                            Text(column.abbreviation)
                                .font(.caption2.weight(.semibold))
                                .gridColumnAlignment(.center)
                        }
                    }
                    Divider()
                    ForEach(reference.panelTests) { test in
                        GridRow {
                            Text(test.name)
                                .font(.footnote)
                                .gridColumnAlignment(.leading)
                            ForEach(Array(zip(reference.panelColumns, test.inPanels).enumerated()), id: \.offset) { _, item in
                                let column = item.0
                                let included = item.1
                                Group {
                                    if included {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.green)
                                    }
                                }
                                .frame(width: 26)
                                .accessibilityLabel("\(test.name): \(included ? "included in" : "not included in") the \(column.fullName)")
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                Text("✓ = test is part of the panel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !reference.panelNote.isEmpty {
                    Text(reference.panelNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(reference.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Commonly Used Panels")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The "therapeutic drug monitoring" table: target and critical levels for
/// each drug. Cells keep the source's trough/peak sub-values on separate
/// lines.
private struct LabTDMView: View {
    let reference: LabReference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Grid(horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Drug")
                            .font(.footnote.weight(.semibold))
                            .gridColumnAlignment(.leading)
                        Text("Low")
                            .font(.footnote.weight(.semibold))
                            .gridColumnAlignment(.leading)
                        Text("High")
                            .font(.footnote.weight(.semibold))
                            .gridColumnAlignment(.leading)
                        Text("Critical High")
                            .font(.footnote.weight(.semibold))
                            .gridColumnAlignment(.leading)
                    }
                    Divider()
                    ForEach(reference.tdmRows) { row in
                        GridRow {
                            Text(row.drug)
                                .font(.footnote.weight(.medium))
                                .gridColumnAlignment(.leading)
                            Text(row.low)
                                .font(.caption)
                                .gridColumnAlignment(.leading)
                            Text(row.high)
                                .font(.caption)
                                .gridColumnAlignment(.leading)
                            Text(row.criticalHigh)
                                .font(.caption)
                                .gridColumnAlignment(.leading)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(row.drug): Low \(row.low), High \(row.high), Critical High \(row.criticalHigh)")
                        Divider()
                    }
                }
                if !reference.tdmNote.isEmpty {
                    Text(reference.tdmNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(reference.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Therapeutic Drug Monitoring")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
