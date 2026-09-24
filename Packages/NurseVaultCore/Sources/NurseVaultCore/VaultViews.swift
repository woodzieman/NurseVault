import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if canImport(PDFKit)
import PDFKit
#endif

/// A PDF preview that works on iPhone, iPad, Mac and Apple Watch.
public struct VaultPDFView: View {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public var body: some View {
        #if canImport(PDFKit)
        PDFRepresentable(data: data)
        #else
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No PDF preview available")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

#if canImport(PDFKit)
#if os(macOS)
private struct PDFRepresentable: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        if let document = PDFDocument(data: data) {
            view.document = document
        }
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil, let document = PDFDocument(data: data) {
            nsView.document = document
        }
    }
}
#else
private struct PDFRepresentable: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        if let document = PDFDocument(data: data) {
            view.document = document
        }
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil, let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}
#endif
#endif

/// An image preview that works on iPhone, iPad, Mac and Apple Watch.
public struct VaultImageView: View {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public var body: some View {
        #if os(macOS)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            placeholder
        }
        #else
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            placeholder
        }
        #endif
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No image preview")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
