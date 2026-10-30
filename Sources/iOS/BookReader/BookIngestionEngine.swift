import Foundation
import PDFKit

/// The BookIngestionEngine handles text extraction from various document formats.
///
/// Optimized for large files (10 MB and up):
/// - PDFs load via `PDFDocument(url:)`, which streams pages from disk on
///   demand instead of reading the entire binary into a `Data` buffer.
/// - RTF is read with `.mappedIfSafe`, so the OS maps the file into virtual
///   memory rather than allocating a physical buffer for the whole file.
/// - Plain text is decoded straight from the URL.
///
/// Deliberately NOT `@MainActor`: `extractText` is `async`, so the CPU-heavy
/// extraction hops off the main actor and the UI stays responsive. PDFKit's
/// *reading* APIs are thread-safe (only drawing needs the main thread), and
/// the engine has no mutable state.
final class BookIngestionEngine: Sendable {
    static let shared = BookIngestionEngine()
    private init() {}

    /// Extracts text from a document at the given URL.
    func extractText(from url: URL, mimeType: String?, fileName: String?) async -> String? {
        if mimeType == "application/pdf" || fileName?.hasSuffix(".pdf") == true {
            return extractTextFromPDF(url: url)
        } else if mimeType == "text/plain" || fileName?.hasSuffix(".txt") == true {
            return extractTextFromPlainText(url: url)
        } else if mimeType == "application/rtf" || fileName?.hasSuffix(".rtf") == true {
            return extractTextFromRTF(url: url)
        }
        return nil
    }

    // MARK: - Format readers

    private func extractTextFromPDF(url: URL) -> String? {
        withSecurityScope(url) {
            // PDFDocument(url:) loads pages on demand — much lighter than
            // PDFDocument(data:) for large books.
            guard let pdf = PDFDocument(url: url) else { return nil }
            var pages: [String] = []
            pages.reserveCapacity(pdf.pageCount)
            for index in 0..<pdf.pageCount {
                if let text = pdf.page(at: index)?.string, !text.isEmpty {
                    pages.append(text)
                }
            }
            // Collect then join: `+=` concatenation is quadratic for long
            // books.
            return finish(pages.joined(separator: "\n"))
        }
    }

    private func extractTextFromPlainText(url: URL) -> String? {
        withSecurityScope(url) {
            if let string = try? String(contentsOf: url, encoding: .utf8) {
                return finish(string)
            }
            // Latin-1 decodes every byte sequence, so it never fails — the
            // same fallback FileSupport.text() uses.
            return finish(try? String(contentsOf: url, encoding: .isoLatin1))
        }
    }

    private func extractTextFromRTF(url: URL) -> String? {
        withSecurityScope(url) {
            guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
                return nil
            }
            guard let attributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) else { return nil }
            return finish(attributedString.string)
        }
    }

    // MARK: - Helpers

    /// Runs `body` with the file's security scope active.
    ///
    /// File-picked URLs are security-scoped on iOS: until the scope is
    /// started, every URL-based read fails (PDFKit returns nil,
    /// `String(contentsOf:)` / `Data(contentsOf:)` throw) — the same
    /// trap `FileSupport` brackets for. For unscoped URLs (e.g. Mac
    /// drag-and-drop) the start/stop is a no-op.
    private func withSecurityScope<R>(_ url: URL, _ body: () -> R) -> R {
        let neededScope = url.startAccessingSecurityScopedResource()
        defer {
            if neededScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return body()
    }

    /// Trims the result; whitespace-only text becomes `nil`.
    private func finish(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
