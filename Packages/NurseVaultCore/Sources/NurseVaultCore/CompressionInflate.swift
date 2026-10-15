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
        // Validate we have enough data for the size prefix
        guard count > MemoryLayout<UInt64>.size else { return nil }
        
        // Read expected uncompressed size from 8-byte little-endian prefix
        let size = withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 0, as: UInt64.self) }
        let expected = UInt64(littleEndian: size)
        
        // Sanity bound: no single reference entry is anywhere near 10 MB.
        guard expected > 0, expected <= 10 * 1024 * 1024 else { return nil }
        
        // Validate compressed data has reasonable size (at least a few bytes)
        let compressedSize = count - MemoryLayout<UInt64>.size
        guard compressedSize > 5 else { return nil }  // Minimum brotli header is ~2 bytes + some data
        
        // Allocate output buffer with extra space for safety margin
        let bufferSize = Int(expected) + 1024  // Add 1KB buffer for edge cases
        guard bufferSize > 0 else { return nil }
        
        var buffer: [UInt8]
        do {
            buffer = try [UInt8](repeating: 0, count: bufferSize)
        } catch {
            return nil  // Memory allocation failed
        }
        
        var written: size_t = 0
        // Skip the 8-byte size prefix - brotli only needs the compressed data
        let sourceCount = count - MemoryLayout<UInt64>.size
        
        let ok = withUnsafeBytes { (source: UnsafeRawBufferPointer) -> Bool in
            buffer.withUnsafeMutableBytes { destination -> Bool in
                // Pass pointer offset by 8 bytes to skip size prefix
                nv_inflate_brotli(
                    source.baseAddress!.advanced(by: MemoryLayout<UInt64>.size),
                    sourceCount,
                    destination.baseAddress,
                    bufferSize,
                    &written
                ) == 0
            }
        }
        
        guard ok else { return nil }
        
        // Validate written size is reasonable
        guard written > 0, written <= buffer.count else { return nil }
        
        return Data(buffer.prefix(Int(written)))
    }
}
