import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if canImport(PDFKit)
import PDFKit
#endif

// MARK: - Image Cache for decoded platform images to avoid re-decoding on every render

/// Thread-safe cache for decoded platform images.
final class ImageCache {
    private let nsCache: NSCache<NSString, AnyObject>
    
    init() {
        nsCache = NSCache()
        // Limit cache to 50 MB total cost (rough estimate)
        nsCache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func image(for data: Data) -> AnyObject? {
        let key = String(data: data, encoding: .ascii) ?? ""
        return nsCache.object(forKey: key as NSString)
    }
    
    func set(_ image: AnyObject, for data: Data) {
        let key = String(data: data, encoding: .ascii) ?? ""
        // Estimate cost based on data size (decoded images are typically larger)
        nsCache.setObject(image, forKey: key as NSString, cost: Int(data.count))
    }
}

/// Shared image cache instance. Access only from the main actor (UI code).
@MainActor let sharedImageCache = ImageCache()

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

/// An image preview that supports pinch-to-zoom (up to 4x) and pan.
///
/// Use this for images that the user adds so they can inspect details.
/// Double-tap resets zoom.
public struct ZoomableImageView: View {
    public let data: Data

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    /// Cached decoded image to avoid re-decoding on every render.
    @State private var cachedImage: AnyObject? = nil

    public init(data: Data) {
        self.data = data
    }

    public var body: some View {
        content
            .accessibilityLabel("Zoomable image")
            .accessibilityHint("Pinch to zoom, two-finger tap to reset")
            .onAppear {
                // Load or create cached image on first appear
                if cachedImage == nil {
                    cachedImage = sharedImageCache.image(for: data) ?? decodeImage(from: data)
                    if let img = cachedImage {
                        sharedImageCache.set(img, for: data)
                    }
                }
            }
    }
    
    private func decodeImage(from data: Data) -> AnyObject? {
        #if os(macOS)
        return NSImage(data: data)
        #else
        return UIImage(data: data)
        #endif
    }

    private var content: some View {
        #if os(watchOS)
        // On watch, delegate to the existing WatchZoomableImageView which
        // handles Digital Crown + drag gestures.
        GeometryReader { proxy in
            if let image = cachedImage as? UIImage ?? UIImage(data: data) {
                WatchZoomableImageView(data: data)
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #elseif os(iOS)
        GeometryReader { proxy in
            if let image = cachedImage as? UIImage ?? UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = clampScale(scale * value.magnitude)
                            }
                            .onEnded { _ in
                                scale = clampScale(scale)
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                if scale <= 1.0 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.35)) {
                            resetZoom()
                        }
                    }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #elseif os(macOS)
        GeometryReader { proxy in
            if let image = cachedImage as? NSImage ?? NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = clampScale(scale * value.magnitude)
                            }
                            .onEnded { _ in
                                scale = clampScale(scale)
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                if scale <= 1.0 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.35)) {
                            resetZoom()
                        }
                    }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    private func clampScale(_ s: CGFloat) -> CGFloat {
        if s < 1.0 { return 1.0 }
        if s > 4.0 { return 4.0 }
        return s
    }

    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
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

// MARK: - Watch Zoomable Image (for watchOS only)

#if os(watchOS)
/// Specialized image view for the Apple Watch that supports zooming with the Digital Crown
/// and panning via drag gestures.
public struct WatchZoomableImageView: View {
    public let data: Data
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    public init(data: Data) {
        self.data = data
    }

    public var body: some View {
        GeometryReader { proxy in
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                if scale <= 1.0 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                    )
                    .focusable()
                    // Map crown rotation to scale (1x to 4x)
                    .digitalCrownRotation($scale, from: 1.0, through: 4.0, by: 0.1)
            } else {
                Text("No image preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        // Keep a reasonable aspect ratio to avoid filling the whole screen vertically in the ScrollView
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
#endif


