import Foundation
import CompressionCompat

extension Data {
    /// Inflates a size-prefixed brotli stream: 8 little-endian bytes giving
    /// the uncompressed length, followed by a standard brotli stream.
    ///
    /// Goes through the `CompressionCompat` C shim (libcompression's
    /// `COMPRESSION_BROTLI`). This is the one inflate path verified on the
    /// Swift 6.4 / SDK 27 toolchain: that SDK's Compression framework has no
    /// importable Swift surface, `NSCompression`'s zlib path fails at runtime
    /// (NSCocoaError 5377), and libcompression's zlib decode silently passes
    /// its input through.
    public func inflatingNV() -> Data? {
        guard count > MemoryLayout<UInt64>.size else { return nil }
        let size = withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 0, as: UInt64.self) }
        let expected = UInt64(littleEndian: size)
        // Sanity bound: no single reference entry is anywhere near 64 MB.
        guard expected > 0, expected <= 64 * 1024 * 1024 else { return nil }
        var buffer = [UInt8](repeating: 0, count: Int(expected))
        let bufferCount = buffer.count
        var written: size_t = 0
        let sourceCount = count
        let ok = withUnsafeBytes { (source: UnsafeRawBufferPointer) -> Bool in
            buffer.withUnsafeMutableBytes { destination -> Bool in
                nv_inflate_brotli(
                    source.baseAddress,
                    sourceCount,
                    destination.baseAddress,
                    bufferCount,
                    &written
                ) == 0
            }
        }
        guard ok, written <= buffer.count else { return nil }
        return Data(buffer.prefix(Int(written)))
    }
}
