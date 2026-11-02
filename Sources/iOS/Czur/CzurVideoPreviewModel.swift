import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Drives the in-app video preview stream for the active CZUR device.
///
/// Frames arrive as raw image bytes (the runtime sends base64-encoded JPEGs);
/// the view decodes them for its platform, so the preview works on both
/// UIKit (iPhone/iPad) and AppKit (Mac).
@MainActor
final class CzurVideoPreviewModel: ObservableObject {
    @Published var frameData: Data?

    private let client: CzurOpenRuntimeClient
    private let deviceId: String
    private var handler: (@Sendable (Data?) -> Void)?

    init(client: CzurOpenRuntimeClient, deviceId: String) {
        self.client = client
        self.deviceId = deviceId
    }

    func start() async throws {
        handler = { data in
            Task { @MainActor in
                self.frameData = data
            }
        }
        client.registerVideoFrameHandler(handler!)
        try await client.startVideo(deviceId: deviceId)
    }

    func stop() async {
        client.clearVideoFrameHandler()
        handler = nil
    }
}
