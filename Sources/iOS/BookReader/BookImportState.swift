import Foundation
import Observation
import SwiftUI

/// UI state for an in-flight book import.
///
/// The ingestion engine reports progress from a background executor; this
/// object is `@MainActor`-isolated so views can observe it safely, and the
/// progress closure hops onto the main actor before mutating it.
@MainActor
@Observable
final class BookImportState {
    var isActive = false
    var fileName: String? = nil
    /// `nil` means “indeterminate”; `0…1` means determinate.
    var progress: Double? = nil
    var error: String? = nil

    func begin(_ name: String) {
        isActive = true
        fileName = name
        progress = 0
        error = nil
    }

    func update(_ fraction: Double) {
        progress = min(max(fraction, 0), 1)
    }

    func finish() {
        isActive = false
        fileName = nil
        progress = nil
    }

    func fail(_ message: String) {
        isActive = false
        progress = nil
        error = message
    }
}

/// A small centered loading bar shown while the book ingestion engine is
/// extracting and indexing text.
struct BookImportProgressOverlay: View {
    @Bindable var state: BookImportState

    var body: some View {
        VStack(spacing: 10) {
            if let progress = state.progress {
                ProgressView(value: progress)
                    .tint(.accentColor)
            } else {
                ProgressView()
            }

            Text(state.fileName.map { "Importing \($0)…" } ?? "Importing book…")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 10)
        .padding()
    }
}
