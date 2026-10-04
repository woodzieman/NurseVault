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
            // Check the size before reading so oversized files (common in
            // folder imports) are rejected without a full file read.
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               size > Int64(maxFileBytes) {
                throw VaultImportError.fileTooLarge(maxMB: maxFileBytes / (1024 * 1024))
            }
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

    /// Whether a URL points at a directory that should be imported as a
    /// folder rather than read as a file.
    ///
    /// File-picked URLs are security-scoped on iOS: until the scope is
    /// started, `resourceValues` throws and `fileExists` reports false, so a
    /// picked folder would look like a missing file. Start the scope for the
    /// duration of the check (a no-op for non-scoped URLs, e.g. Mac drops).
    public static func isDirectory(at url: URL) -> Bool {
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        if let isDirectory = values?.isDirectory {
            return isDirectory
        }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    /// The entries of a directory (subdirectories first, both name-sorted),
    /// excluding hidden items. Returns an empty array when the directory
    /// can't be read.
    public static func directoryEntries(at url: URL) -> [URL] {
        // Same scoping rule as `isDirectory`: `contentsOfDirectory` on an
        // unscoped, security-scoped URL (as file-picked on iOS) throws and
        // would silently import the folder as empty.
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else { return [] }
        var result: [URL] = []
        for entry in entries where !entry.lastPathComponent.hasPrefix(".") {
            result.append(entry)
        }
        let directories = result.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
        let files = result.filter { ((try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory) != true }
            .sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
        return directories + files
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
