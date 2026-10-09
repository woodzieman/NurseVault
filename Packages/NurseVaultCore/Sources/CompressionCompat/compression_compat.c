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
    size_t scratch = compression_decode_scratch_buffer_size(COMPRESSION_BROTLI);
    void *scratchBuf = scratch > 0 ? malloc(scratch) : NULL;
    if (scratch > 0 && scratchBuf == NULL) {
        return -1;
    }
    int result = compression_decode_buffer(out, out_cap, in, in_len, scratchBuf, COMPRESSION_BROTLI);
    free(scratchBuf);
    if (result < 0) {
        return -1;
    }
    *out_len = (size_t)result;
    return 0;
}
