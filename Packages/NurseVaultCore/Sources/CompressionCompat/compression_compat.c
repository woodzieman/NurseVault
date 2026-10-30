#include "compression_compat.h"

#include <compression.h>
#include <stdlib.h>
#include <string.h>

int nv_inflate_brotli(const uint8_t *in,
                      size_t in_len,
                      uint8_t *out,
                      size_t out_cap,
                      size_t *out_len) {
    if (in == NULL || out == NULL || out_len == NULL || in_len == 0) {
        return -1;
    }
    
    // Validate input is large enough for brotli header
    if (in_len < 2) {
        return -1;  // Too small to be valid brotli data
    }
    
    size_t scratch = compression_decode_scratch_buffer_size(COMPRESSION_BROTLI);
    void *scratchBuf = NULL;
    
    if (scratch > 0 && scratch < 1024 * 1024) {  // Cap scratch buffer at 1 MB
        scratchBuf = malloc(scratch);
        if (scratchBuf == NULL) {
            return -1;  // Memory allocation failed
        }
    }
    
    /* compression_decode_buffer() returns size_t: the number of bytes written on
     * success, or 0 if decompression fails. Callers cap output buffers at the
     * 10 MB entry limit (see CompressionInflate.swift), so truncation cannot occur. */
    size_t result = compression_decode_buffer(out, out_cap, in, in_len, scratchBuf, COMPRESSION_BROTLI);
    free(scratchBuf);
    
    if (result == 0) {
        return -1;  // Decompression failed
    }
    
    *out_len = result;
    return 0;
}
