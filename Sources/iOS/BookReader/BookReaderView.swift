import SwiftUI
import NurseVaultCore

struct BookReaderView: View {
    let doc: VaultDoc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if let data = doc.fileData {
                readerContent(data: data)
            } else if let note = doc.noteText, !note.isEmpty {
                ScrollView {
                    Text(note)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView("No Content", systemImage: "doc.text")
            }
        }
        .navigationTitle(doc.title ?? "Reader")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private func readerContent(data: Data) -> some View {
        let mimeType = doc.mimeType ?? ""
        let fileName = doc.fileName ?? ""

        if mimeType == "application/pdf" || fileName.hasSuffix(".pdf") {
            VaultPDFView(data: data)
                .ignoresSafeArea()
        } else if mimeType == "text/plain" || fileName.hasSuffix(".txt") || mimeType == "application/rtf" || fileName.hasSuffix(".rtf") {
            ScrollView {
                Text(FileSupport.text(from: data) ?? "Unable to load text content.")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView("Unsupported Format", systemImage: "doc.questionmark")
        }
    }
}
