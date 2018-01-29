#include <stdio.h>
#include <stdint.h>
#include <openssl/rand.h>

#include <urweb.h>

#include "uuid.h"

uw_Basis_string uw_Uuid_random(uw_context ctx) {
  uint8_t buf[16];
  { FILE *urand = fopen("/dev/urandom", "r");
    if (!urand) {
      uw_error(ctx, FATAL, "Failed to open /dev/urandom");
    }

    size_t read = fread(&buf, 1, 16, urand);
    if (!read || read < 16) {
      fclose(urand);
      uw_error(ctx, BOUNDED_RETRY, "Failed to read from /dev/urandom");
    }

    int ok = fclose(urand);
    if (ok != 0) {
      uw_error(ctx, BOUNDED_RETRY, "Failed to close /dev/urandom");
    }
  }

  // Set the leftmost bits to 0100 to set version 4
  buf[6] &= 0x0F;
  buf[6] |= 0x40;

  // Set the leftmost bits to 10 to set variant 1
  buf[8] &= 0x3F;
  buf[8] |= 0x80;

  char *out = uw_malloc(ctx, 37);
  sprintf(out,
    "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
    buf[0], buf[1], buf[2],  buf[3],  buf[4],  buf[5],  buf[6],  buf[7],
    buf[8], buf[9], buf[10], buf[11], buf[12], buf[13], buf[14], buf[15]
  );

  return out;
}
