#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <openssl/md5.h>

#include <urweb.h>

#include "fileFfi.h"


#define NEGOTO_STATIC_DIR "public"




uw_unit uw_FileFfi_save(uw_context ctx, uw_Basis_string section, uw_Basis_string name, uw_Basis_file file) {
  return 0;
}
uw_unit uw_FileFfi_delete(uw_context ctx, uw_Basis_string section, uw_Basis_string name) {
  return 0;
}

union image_result {
  struct {
    char hash[32];
    char width[4];
    char height[4];
    char eos; // NULL
  };
  char buf[41];
};


uw_Basis_string uw_FileFfi_saveImage(uw_context ctx, uw_Basis_string ext, uw_Basis_file file) {
  uint8_t *hash = (uint8_t *)malloc(MD5_DIGEST_LENGTH);
  MD5((unsigned char *)file.data.data, file.data.size, hash);

  // Pack the result into the result array
  union image_result *result = uw_malloc(ctx, sizeof(union image_result));
  result->eos = '\0';

  for (int i = 0; i < MD5_DIGEST_LENGTH; i++)
    sprintf(result->hash + (i * 2), "%02x", hash[i]);

  sprintf(result->width, "%04d", 300);
  sprintf(result->height, "%04d", 300);

  return result->buf;
}



uw_Basis_string uw_FileFfi_link(uw_context ctx, uw_Basis_string section, uw_Basis_string name) {
  return name;
}
