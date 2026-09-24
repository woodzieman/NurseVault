import SwiftUI
import WidgetKit
import NurseVaultCore

/// Entry point of the widget extension. On Apple Watch, the accessory
/// families below appear as watch-face complications and Smart Stack
/// items. Tapping the complication opens the Nurse Vault app.
@main
struct NurseVaultWidgetBundle: WidgetBundle {
    var body: some Widget {
        NurseVaultComplication()
    }
}

// MARK: - Entry

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: VaultSummary.Snapshot?

    var documentCount: Int? { snapshot?.documentCount }

    static let sample = ComplicationEntry(
        date: .now,
        snapshot: VaultSummary.Snapshot(sectionCount: 4, documentCount: 42, updatedAt: .now)
    )

    static let empty = ComplicationEntry(date: .now, snapshot: nil)
}

// MARK: - Provider

/// Reads the summary the app writes next to its Core Data store. The
/// widget and the watch app share the watch app's container; when the
/// file isn't there yet (fresh install, before the app first runs) the
/// entry falls back to the plain app name.
struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: TimelineProviderContext) -> ComplicationEntry {
        ComplicationEntry.empty
    }

    func getSnapshot(
        in context: TimelineProviderContext,
        completion: @escaping @Sendable (ComplicationEntry) -> Void
    ) {
        Task {
            completion(await Self.currentEntry())
        }
    }

    func getTimeline(
        in context: TimelineProviderContext,
        completion: @escaping @Sendable (Timeline<ComplicationEntry>) -> Void
    ) {
        Task {
            let entry = await Self.currentEntry()
            let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date) ?? entry.date
            completion(Timeline(entries: [entry], policy: .after(refresh)))
        }
    }

    private static func currentEntry() async -> ComplicationEntry {
        let snapshot = await Task.detached(priority: .utility) {
            VaultSummary.load()
        }.value
        return ComplicationEntry(date: .now, snapshot: snapshot)
    }
}

// MARK: - Widget

struct NurseVaultComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: VaultWidget.complicationKind,
            provider: ComplicationProvider()
        ) { entry in
            ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Nurse Vault")
        .description("A quick glance at your reference vault.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

// MARK: - Entry view

struct ComplicationEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ComplicationEntry

    private var icon: Image {
        Image(systemName: "cross.case.fill")
    }

    private var subtitle: String {
        if let count = entry.documentCount {
            return count == 1 ? "1 reference" : "\(count) references"
        }
        return "Open the app"
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                VStack(spacing: 1) {
                    icon
                        .imageScale(.large)
                    if let count = entry.documentCount {
                        Text("\(count)")
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                    }
                }
                .widgetLabel {
                    Text("Nurse Vault")
                }
            case .accessoryCorner:
                icon
                    .imageScale(.large)
                    .widgetLabel {
                        Text("Nurse Vault")
                    }
            case .accessoryInline:
                Text(entry.documentCount == nil ? "Nurse Vault" : subtitle)
            case .accessoryRectangular:
                HStack(spacing: 6) {
                    icon
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Nurse Vault")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                        Text(subtitle)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            @unknown default:
                Text("Nurse Vault")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    NurseVaultComplication()
} timeline: {
    ComplicationEntry.sample
    ComplicationEntry.empty
}

#Preview(as: .accessoryCorner) {
    NurseVaultComplication()
} timeline: {
    ComplicationEntry.sample
    ComplicationEntry.empty
}

#Preview(as: .accessoryInline) {
    NurseVaultComplication()
} timeline: {
    ComplicationEntry.sample
    ComplicationEntry.empty
}

#Preview(as: .accessoryRectangular) {
    NurseVaultComplication()
} timeline: {
    ComplicationEntry.sample
    ComplicationEntry.empty
}
