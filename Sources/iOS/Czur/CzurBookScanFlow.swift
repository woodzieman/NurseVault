import Foundation
import NurseVaultCore

#if canImport(UIKit)
import UIKit
#endif

/// Orchestrates scanning a book with the CZUR ET Max through the local CZUR
/// Open SDK Runtime and saving the result into the NurseVault library.
@MainActor
@Observable
final class CzurBookScanFlow {
    static let shared = CzurBookScanFlow()
    init() {}

    enum ScanPhase: Equatable {
        case idle
        case connecting
        case scanning
        case processing
        case saving
        case completed
        case failed(String)
    }

    enum ScanOutcome {
        case saved
        case cancelled
        case failed(String)
    }

    /// Tunables for a single scan. Defaults preserve the shipped behavior.
    struct ScanOptions {
        /// Enables the runtime page-turn detection + auto-capture flow.
        var autoCaptureEnabled: Bool = false
        /// OCR language code (e.g. "en"); nil keeps the runtime / device default.
        var ocrLanguage: String? = nil
        /// Enables the runtime image-enhancement pipeline on captured pages.
        var imageEnhancementEnabled: Bool = false
        /// Starts a runtime video preview stream (`video.start`) during the scan.
        var videoPreviewEnabled: Bool = false
        /// Converts captured pages into a PDF via the runtime `file.convert`
        /// capability and saves the converted PDF into the library.
        var convertCapturedPagesToPdf: Bool = false
        /// Optional scanner device to target; nil picks the first CZUR device.
        var deviceId: String? = nil
    }

    private(set) var phase: ScanPhase = .idle
    private(set) var lastError: String? = nil
    private(set) var activeDeviceId: String? = nil
    private(set) var devices: [CzurOpenDevice] = []

    /// Scans a book via the connected CZUR scanner, OCRs the captured pages,
    /// and stores the searchable text in the library as a book document.
    ///
    /// - Parameters:
    ///   - title: The book's title (document name).
    ///   - section: Vault section to save into; nil for the vault top level.
    ///   - folder: Folder within the section; nil for the section top level.
    func scanAndSaveBook(
        library: Library,
        title: String,
        section: VaultSection? = nil,
        folder: VaultFolder? = nil,
        options: ScanOptions = ScanOptions()
    ) async -> ScanOutcome {
        phase = .connecting
        let client = CzurOpenRuntimeClient.shared
        let reachable = await client.checkRuntimeReachable()
        if !reachable {
            lastError = CzurOpenError.runtimeNotRunning.errorDescription
            phase = .failed(CzurOpenError.runtimeNotRunning.errorDescription ?? "The local CZUR scanner runtime is not running.")
            return .failed(CzurOpenError.runtimeNotRunning.errorDescription ?? "The local CZUR scanner runtime is not running.")
        }

        do {
            try await client.createSession()
            phase = .scanning
            let devices = try await client.listDevices()
            self.devices = devices
            let device = options.deviceId.flatMap { deviceId in
                devices.first { $0.deviceId == deviceId }
            } ?? devices.first(where: { ($0.name ?? "").contains("ET") }) ?? devices.first
            guard let device else {
                phase = .failed(CzurOpenError.deviceNotFound.errorDescription ?? "No CZUR scanner was found.")
                return .failed(CzurOpenError.deviceNotFound.errorDescription ?? "No CZUR scanner was found.")
            }
            try await client.openDevice(deviceId: device.deviceId)
            activeDeviceId = device.deviceId
            if options.autoCaptureEnabled {
                try await client.setTurnDetect(deviceId: device.deviceId, enabled: true, autoCapture: true, cooldownMs: 1000)
            }
            if options.videoPreviewEnabled {
                try await client.startVideo(deviceId: device.deviceId)
            }

            let taskId = try await client.takeCapture(
                deviceId: device.deviceId,
                outputDir: nil,
                pipeline: options.imageEnhancementEnabled ? ["version": "image.enhance.pipeline.v1"] : nil
            )
            var task = try await client.getCapture(taskId: taskId)

            var elapsed: TimeInterval = 0
            while task.status != "completed" && task.status != "failed" && task.status != "cancelled" {
                if task.status == "failed" {
                    phase = .failed(CzurOpenError.scanFailed(task.status).errorDescription ?? "The CZUR scan failed.")
                    return .failed(CzurOpenError.scanFailed(task.status).errorDescription ?? "The CZUR scan failed.")
                }
                try await Task.sleep(nanoseconds: 500_000_000)
                task = try await client.getCapture(taskId: taskId)
                elapsed += 0.5
                if elapsed > 120 {
                    phase = .failed("The CZUR scan timed out.")
                    return .failed("The CZUR scan timed out.")
                }
            }

            if task.status == "cancelled" {
                phase = .idle
                return .cancelled
            }
            if task.status == "failed" {
                phase = .failed(CzurOpenError.scanFailed(task.status).errorDescription ?? "The CZUR scan failed.")
                return .failed(CzurOpenError.scanFailed(task.status).errorDescription ?? "The CZUR scan failed.")
            }

            phase = .processing
            var ocrText = ""
            for assetId in task.assets {
                let data = try await client.downloadAsset(taskId: taskId, assetId: assetId)
                #if canImport(UIKit)
                let image = UIImage(data: data)
                if let image {
                    let pageText = try? await OCRSupport.recognizeText(
                        image: image,
                        recognitionLanguages: options.ocrLanguage.map { [$0] } ?? ["en"]
                    )
                    if let pageText, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if !ocrText.isEmpty {
                            ocrText += "\n\n"
                        }
                        ocrText += pageText
                    }
                }
                #endif
            }

            var barcodeText = ""
            if !task.assets.isEmpty {
                let finalAssetId = task.assets[task.assets.count - 1]
                let barcode = try? await client.detectBarcodes(
                    inputUploadId: finalAssetId,
                    formats: ["qrcode", "pdf417", "code128", "ean13", "ean8", "upca", "upce", "code39", "codabar"]
                )
                if let barcode, barcode.detected, !barcode.barcodes.isEmpty {
                    var lines: [String] = []
                    for info in barcode.barcodes {
                        if let type = info.type, let value = info.value {
                            lines.append("\(type): \(value)")
                        }
                    }
                    barcodeText = lines.joined(separator: "\n")
                }
            }

            var content = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !barcodeText.isEmpty {
                if !content.isEmpty { content += "\n\n" }
                content += barcodeText
            }
            guard !content.isEmpty else {
                phase = .failed("The CZUR scan did not produce readable text.")
                return .failed("The CZUR scan did not produce readable text.")
            }

            if options.videoPreviewEnabled {
                try await client.stopVideo(deviceId: device.deviceId)
            }
            phase = .saving
            var imported: ImportedFile = ImportedFile(
                data: content.data(using: .utf8) ?? Data(content.utf8),
                fileName: "\(title).txt",
                title: title,
                mimeType: "text/plain"
            )

            if options.convertCapturedPagesToPdf, !task.assets.isEmpty {
                // Convert the captured pages into a PDF via the runtime
                // `file.convert` capability, then save the converted PDF into
                // the library alongside the OCR text.
                let conversionTaskId = try await client.convertCapture(taskId: taskId, exportType: "pdf", renderDpi: 144)
                var conversionTask = try await client.getFileConversion(taskId: conversionTaskId)
                var conversionElapsed: TimeInterval = 0
                while conversionTask.status != "completed" && conversionTask.status != "failed" && conversionTask.status != "cancelled" {
                    if conversionTask.status == "failed" {
                        phase = .failed(CzurOpenError.conversionFailed(conversionTask.status).errorDescription ?? "The CZUR file conversion failed.")
                        return .failed(CzurOpenError.conversionFailed(conversionTask.status).errorDescription ?? "The CZUR file conversion failed.")
                    }
                    try await Task.sleep(nanoseconds: 500_000_000)
                    conversionTask = try await client.getFileConversion(taskId: conversionTaskId)
                    conversionElapsed += 0.5
                    if conversionElapsed > 120 {
                        phase = .failed("The CZUR file conversion timed out.")
                        return .failed("The CZUR file conversion timed out.")
                    }
                }
                if conversionTask.status == "failed" {
                    phase = .failed(CzurOpenError.conversionFailed(conversionTask.status).errorDescription ?? "The CZUR file conversion failed.")
                    return .failed(CzurOpenError.conversionFailed(conversionTask.status).errorDescription ?? "The CZUR file conversion failed.")
                }
                guard conversionTask.status == "completed" else {
                    phase = .failed("The CZUR file conversion did not complete.")
                    return .failed("The CZUR file conversion did not complete.")
                }
                guard let pdfAssetId = conversionTask.assets.first, let pdfData = try? await client.downloadAsset(taskId: conversionTaskId, assetId: pdfAssetId) else {
                    phase = .failed("The CZUR file conversion did not return a PDF asset.")
                    return .failed("The CZUR file conversion did not return a PDF asset.")
                }
                imported = ImportedFile(
                    data: pdfData,
                    fileName: "\(title).pdf",
                    title: title,
                    mimeType: "application/pdf"
                )
            }

            library.addDocument(
                imported: imported,
                noteText: content,
                to: section,
                in: folder
            )
            phase = .completed
            return .saved
        } catch {
            phase = .failed(error.localizedDescription)
            return .failed(error.localizedDescription)
        }
    }
}
