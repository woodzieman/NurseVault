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
                if !reference.valueGroups.isEmpty {
                    Section {
                        NavigationLink("Normal Lab Values") {
                            LabValuesView(reference: reference)
                        }
                    } footer: {
                        Text("Typical adult ranges and what each test measures.")
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
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(reference.allSources) { source in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(source.text)
                                if let url = URL(string: source.url) {
                                    Link("View source", destination: url)
                                }
                            }
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

/// Normal lab values, grouped by category. Each row shows the test name,
/// typical adult range, and a concise description.
private struct LabValuesView: View {
    let reference: LabReference

    var body: some View {
        List {
            ForEach(reference.valueGroups) { group in
                Section(group.title) {
                    ForEach(group.tests) { entry in
                        LabValueRow(entry: entry)
                    }
                }
            }
        }
        .navigationTitle("Normal Lab Values")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Maps a collection-tube color name (e.g. "Gold") to a swatch color.
private enum LabTubeColor {
    static func color(for name: String) -> Color? {
        switch name.lowercased() {
        case "gold": return Color.orange
        case "green": return Color.green
        case "lavender": return Color.purple
        case "red": return Color.red
        case "blue": return Color.blue
        case "gray": return Color.gray
        default: return nil
        }
    }
}

private struct LabValueRow: View {
    let entry: LabValueEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Collection tube color — rendered as a color swatch at the top of the row.
            if let tubeColor = entry.tubeColor, !tubeColor.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LabTubeColor.color(for: tubeColor) ?? Color.secondary)
                        .frame(width: 10, height: 10)
                    Text("Tube: \(tubeColor)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(entry.name)
                .font(.body.weight(.medium))
            Text(entry.range)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(entry.description)
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
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
                ForEach(reference.allSources) { source in
                    Text(source.text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
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
                ForEach(reference.allSources) { source in
                    Text(source.text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Therapeutic Drug Monitoring")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
