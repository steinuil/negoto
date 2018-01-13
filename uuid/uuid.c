#include <stdio.h>
#include <stdint.h>
#include <openssl/rand.h>

#include <urweb.h>

#include "uuid.h"

uw_Basis_string uw_Uuid_random(uw_context ctx) {
  union {
    struct {
      uint32_t time_low;
      uint16_t time_mid;
      uint16_t time_hi_and_version;
      uint8_t clock_seq_hi_and_res;
      uint8_t clock_seq_low;
      uint16_t node[3];
    };
    uint8_t buf[16];
  } uuid;

  int ok = RAND_bytes(uuid.buf, sizeof(uint8_t) * 16);
  if (!ok) {
    uw_error(ctx, UNLIMITED_RETRY, "Failed to get random bytes");
  }

  // Set the leftmost bits to 0100 to set version 4
  uuid.time_hi_and_version &= 0xFFF;
  uuid.time_hi_and_version |= 0x4000;

  // Set the leftmost bits to 10 to set the variant
  uuid.clock_seq_hi_and_res &= 0x3F;
  uuid.clock_seq_hi_and_res |= 0x80;

  char *buf = (char *)uw_malloc(ctx, 37);
  sprintf(buf, "%08x-%04x-%04x-%02x%02x-%04x%04x%04x",
    uuid.time_low, uuid.time_mid, uuid.time_hi_and_version,
    uuid.clock_seq_hi_and_res, uuid.clock_seq_low,
    uuid.node[0], uuid.node[1], uuid.node[2]
  );

  return buf;
}
