import SwiftUI

/// Status and progress UI for the CZUR ET Max book-scan flow.
struct CzurScanProgressView: View {
    let phase: CzurBookScanFlow.ScanPhase

    var body: some View {
        VStack(spacing: 10) {
            switch phase {
            case .idle:
                Label("Ready to scan", systemImage: "book.closed")
            case .connecting:
                ProgressView()
                Text("Connecting to the CZUR scanner…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .scanning:
                ProgressView()
                Text("Scanning book pages…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .processing:
                ProgressView()
                Text("Reading text…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .saving:
                ProgressView()
                Text("Saving to your library…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .completed:
                Label("Scan complete", systemImage: "checkmark.circle.fill")
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
