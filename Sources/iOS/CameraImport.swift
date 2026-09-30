import SwiftUI
import NurseVaultCore
#if canImport(UIKit)
import UIKit
import Vision
import CoreGraphics
import ImageIO
#endif

/// Camera capture and document OCR for the Add menu.
///
/// These are only offered where a live camera makes sense (iPhone and
/// iPads with a camera): the Mac hides both buttons, and the watch app
/// is read-only. Everything runs on device — the camera and the Vision
/// OCR never touch the network.
enum CameraSupport {
    #if canImport(UIKit)
    @MainActor static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    #else
    static let isAvailable = false
    #endif
}

#if canImport(UIKit)

/// The capture + OCR content for the Take Photo and Scan & OCR import
/// flows. Rendered inside `ImportView`'s form; saves directly to the
/// library and dismisses.
struct CameraImportSection: View {
    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss

    let kind: ImportKind
    let section: VaultSection?
    /// The folder the capture started from, if any.
    var folder: VaultFolder? = nil
    /// Resolves the save folder at save time (the parent ImportView owns
    /// folder creation for its "New Folder…" option). When nil, `folder` is
    /// used as-is.
    var resolveFolder: (@MainActor () -> VaultFolder?)? = nil

    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var ocrTitle = ""
    @State private var ocrText = ""
    @State private var ocrInProgress = false
    @State private var showingErrorAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            Section {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("Retake", systemImage: "arrow.clockwise") {
                        capturedImage = nil
                        if kind == .ocr {
                            ocrText = ""
                        }
                        showingCamera = true
                    }
                } else {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Open Camera", systemImage: "camera")
                    }
                }
            } footer: {
                Text(
                    kind == .ocr
                        ? "Point the camera at a printed reference — a drug label, a lab sheet — and capture it. The text is read on device and becomes an editable, searchable note."
                        : "Captures a photo from the camera and stores it as an image that syncs like any other document."
                )
            }

            if kind == .ocr {
                Section("Recognized Text") {
                    TextField("Title", text: $ocrTitle)
                    TextField("Recognized text", text: $ocrText, axis: .vertical)
                        .lineLimit(5...16)
                }
            }

            Section {
                if kind == .camera {
                    Button("Save Photo", systemImage: "checkmark") {
                        saveCapturedPhoto()
                    }
                    .disabled(capturedImage == nil)
                } else {
                    Button(ocrInProgress ? "Reading…" : "Save Note", systemImage: "checkmark") {
                        saveOCRNote()
                    }
                    .disabled(ocrInProgress || ocrText.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureSheet(isPresented: $showingCamera) { captured in
                capturedImage = captured
                if kind == .ocr {
                    startOCR(captured)
                }
            }
        }
        .alert("Couldn't Save", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveCapturedPhoto() {
        guard let capturedImage,
              let data = capturedImage.jpegData(compressionQuality: 0.8) else { return }
        let name = "photo-\(Int(Date.now.timeIntervalSince1970)).jpg"
        if let imported = try? FileSupport.importFile(
            data: data,
            suggestedName: name,
            suggestedMIMEType: "image/jpeg"
        ) {
            let targetFolder = resolveFolder?() ?? folder
            library.addDocument(
                imported: imported,
                to: targetFolder?.section ?? section,
                in: targetFolder
            )
            dismiss()
        } else {
            errorMessage = "The photo couldn't be imported."
            showingErrorAlert = true
        }
    }

    private func startOCR(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            ocrInProgress = false
            return
        }
        ocrInProgress = true
        Task {
            do {
                ocrText = try await OCRSupport.recognizeText(jpegData: data)
            } catch {
                errorMessage = "Couldn't read text from the photo. Retake it in better light, or type the text yourself."
                showingErrorAlert = true
            }
            ocrInProgress = false
        }
    }

    private func saveOCRNote() {
        let trimmed = ocrTitle.trimmingCharacters(in: .whitespaces)
        let date = Date.now.formatted(date: .abbreviated, time: .omitted)
        let targetFolder = resolveFolder?() ?? folder
        library.addNote(
            title: trimmed.isEmpty ? "Scanned \(date)" : trimmed,
            body: ocrText,
            to: targetFolder?.section ?? section,
            in: targetFolder
        )
        dismiss()
    }
}

/// Hosts the full-screen `UIImagePickerController` camera UI in a sheet.
struct CameraCaptureSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        context.coordinator.isPresented = $isPresented
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        var isPresented: Binding<Bool>?

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if let image {
                onCapture(image)
            }
            // Close the sheet hosting the camera UI.
            isPresented?.wrappedValue = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isPresented?.wrappedValue = false
        }
    }
}

/// On-device text recognition (Apple Vision) for scanned documents.
enum OCRSupport {

    enum Error: LocalizedError {
        case noImage

        var errorDescription: String? {
            switch self {
            case .noImage: "The photo couldn't be read."
            }
        }
    }

    /// Recognizes the text of a JPEG, one recognized line per row.
    ///
    /// The whole request is built and run on one detached thread, so no
    /// non-Sendable Vision objects cross actor boundaries.
    static func recognizeText(jpegData: Data) async throws -> String {
        let task = Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(jpegData as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw Error.noImage
            }
            var performError: Swift.Error?
            var text: String?
            let request = VNRecognizeTextRequest { recognition, error in
                if let error {
                    performError = error
                    return
                }
                // The current SDK reports VNRecognizedTextObservation results.
                let lines = recognition.results?
                    .compactMap { ($0 as? VNRecognizedTextObservation)?.topCandidates(1).first?.string } ?? []
                text = lines.joined(separator: "\n")
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            if let performError {
                throw performError
            }
            return text ?? ""
        }
        return try await task.value
    }
}

#endif
