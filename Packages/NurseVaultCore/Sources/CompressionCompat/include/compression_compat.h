#ifndef NV_COMPRESSION_COMPAT_H
#define NV_COMPRESSION_COMPAT_H

#include <stddef.h>
#include <stdint.h>

/// Inflates a standard brotli stream.
///
/// The caller must size `out` to the expected *uncompressed* size — Apple's
/// libcompression cannot report the required size. On success the
/// decompressed byte count is written to `out_len` and 0 is returned; on
/// failure -1 is returned and `out_len` is left untouched.
///
/// A thin C bridge over `compression_decode_buffer(..., COMPRESSION_BROTLI)`.
/// The Compression framework's Swift surface is not importable with the
/// Swift 6.4 / SDK 27 toolchain, `NSCompression` has no brotli (and its zlib
/// path fails at runtime on that SDK, NSCocoaError 5377), and
/// libcompression's zlib decode silently passes its input through — brotli is
/// the one decode path verified to round-trip.
int nv_inflate_brotli(const uint8_t *in,
                      size_t in_len,
                      uint8_t *out,
                      size_t out_cap,
                      size_t *out_len);

#endif
