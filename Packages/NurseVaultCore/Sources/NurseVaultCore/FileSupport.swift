import Foundation
import UniformTypeIdentifiers

public enum VaultImportError: LocalizedError {
    case fileTooLarge(maxMB: Int)
    case unreadable(String)

    public var errorDescription: String? {
        switch self {
        case .fileTooLarge(let maxMB):
            return "That file is too large. The maximum size is \(maxMB) MB."
        case .unreadable(let name):
            return "Couldn’t read “\(name)”. Make sure it isn’t locked or corrupted."
        }
    }
}

/// The result of reading a file from disk / the Photos library.
public struct ImportedFile: Sendable {
    public var data: Data
    public var fileName: String
    public var title: String
    public var mimeType: String?
}

/// Helpers for turning picked files and photos into library documents.
public enum FileSupport {

    /// CloudKit comfortably handles up to 50 MB per record; we leave headroom.
    public static let maxFileBytes = 48 * 1024 * 1024

    public static func importFile(at url: URL) throws -> ImportedFile {
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            guard data.count <= maxFileBytes else {
                throw VaultImportError.fileTooLarge(maxMB: maxFileBytes / (1024 * 1024))
            }
            let name = url.lastPathComponent
            let title = url.deletingPathExtension().lastPathComponent
            let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            return ImportedFile(data: data, fileName: name, title: title, mimeType: mimeType)
        } catch {
            throw VaultImportError.unreadable(url.lastPathComponent)
        }
    }

    /// Imports raw data (e.g. from the Photos picker) where no file URL exists.
    public static func importFile(
        data: Data,
        suggestedName: String? = nil,
        suggestedMIMEType: String? = nil
    ) throws -> ImportedFile {
        guard data.count <= maxFileBytes else {
            throw VaultImportError.fileTooLarge(maxMB: maxFileBytes / (1024 * 1024))
        }

        let name = suggestedName ?? "document"
        let mimeType = suggestedMIMEType
        let title = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent

        return ImportedFile(data: data, fileName: name, title: title, mimeType: mimeType)
    }

    /// Best-effort UTF-8/latin1 decoding for text documents.
    public static func text(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        return String(data: data, encoding: .isoLatin1)
    }
}

/// What a document contains, used to pick icons and preview renderers.
public enum DocKind: Sendable {
    case pdf
    case image
    case text
    case other
    case note

    public static func kind(mimeType: String?, fileName: String?, hasFile: Bool) -> DocKind {
        if !hasFile {
            return .note
        }
        let mime = (mimeType ?? "").lowercased()
        let name = (fileName ?? "").lowercased()
        if mime == "application/pdf" || name.hasSuffix(".pdf") {
            return .pdf
        }
        if mime.hasPrefix("image/") ||
            [".png", ".jpg", ".jpeg", ".heic", ".heif", ".gif", ".webp", ".svg", ".bmp"].contains(name) {
            return .image
        }
        if mime.hasPrefix("text/") || [".txt", ".md", ".csv"].contains(name) {
            return .text
        }
        return .other
    }

    public var systemImage: String {
        switch self {
        case .pdf: "doc.richtext"
        case .image: "photo"
        case .text: "note.text"
        case .other: "doc"
        case .note: "text.quote"
        }
    }
}
