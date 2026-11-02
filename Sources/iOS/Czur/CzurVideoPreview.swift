import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Live video frame preview for the active CZUR device, fed by the runtime
/// video frame stream (`video.start` → frames → handler → `frameData`).
struct CzurVideoPreview: View {
    @StateObject private var model: CzurVideoPreviewModel

    init(client: CzurOpenRuntimeClient, deviceId: String) {
        _model = StateObject(wrappedValue: CzurVideoPreviewModel(client: client, deviceId: deviceId))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let frameData = model.frameData {
                frameView(for: frameData)
            } else {
                Text("Waiting for video…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            try? await model.start()
        }
        .onDisappear {
            Task { await model.stop() }
        }
    }

    @ViewBuilder
    private func frameView(for data: Data) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        }
        #endif
    }
}
