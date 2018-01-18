#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <openssl/md5.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <urweb.h>

#include "fileFfi.h"


#define NEGOTO_STATIC_DIR "public"
#define NEGOTO_STATIC_URL "/static"


uw_Basis_string uw_FileFfi_md5Hash(uw_context ctx, uw_Basis_file file) {
  uint8_t *hash = (uint8_t *)malloc(MD5_DIGEST_LENGTH);
  MD5((unsigned char *)file.data.data, file.data.size, hash);

  char *hex = (char *)uw_malloc(ctx, (MD5_DIGEST_LENGTH * 2) + 1);
  for (int i = 0; i < MD5_DIGEST_LENGTH; i++)
    sprintf(hex + (i * 2), "%02x", hash[i]);

  free(hash);
  return hex;
}


struct save_t {
  uw_context ctx;
  uw_Basis_string name;
  char *file;
  size_t size;
};


// Saving
static void save_file(void *data) {
  struct save_t *a = data;

  FILE *f = fopen(a->name, "w");
  if (!f) {
    uw_set_error_message(a->ctx, "Failed to open %s", a->name);
    return;
  }

  size_t written = fwrite(a->file, sizeof(char), a->size, f);
  if (written < sizeof(char) / a->size) {
    uw_set_error_message(a->ctx, "Failed to write %s", a->name);
  }

  int ok = fclose(f);
  if (ok != 0) {
    uw_set_error_message(a->ctx, "Failed to close %s", a->name);
  }
}


// Deleting
static void delete_file(void *data) {
  struct save_t *a = data;

  if (access(a->name, F_OK) == 0)
    unlink(a->name);
}


static void delete_filename(void *data) {
  char *name = (char *)data;
  if (access(name, F_OK) == 0)
    unlink(name);
}


// Free handlers
static void free_file(void *data, int will_retry) {
  if (data) {
    struct save_t *a = data;
    if (a->name) free(a->name);
    if (a->file) free(a->file);
    free(a);
  }
}


static void free_filename(void *data, int will_retry) {
  if (data) free(data);
}


struct dirname_t {
  uw_context ctx;
  char *name;
};


static void free_dirname(void *data, int will_retry) {
  if (data) {
    struct dirname_t *d = data;
    if (d->name) free(d->name);
    free(d);
  }
}


// Make directories
static void create_dir(void *data) {
  struct dirname_t *dirname = data;
  struct stat *s = {0};

  if (stat(dirname->name, s) == -1) {
    int ok = mkdir(dirname->name, 0700);
    if (ok != 0)
      uw_set_error_message(dirname->ctx, "Failed to create directory %s", dirname->name);
  }
}


uw_unit uw_FileFfi_mkdir(uw_context ctx, uw_Basis_string name) {
  struct dirname_t *d = malloc(sizeof(struct dirname_t));
  d->ctx = ctx;
  size_t len = sizeof(NEGOTO_STATIC_DIR) + 1 + 16 + 1;
  d->name = malloc(len);
  snprintf(d->name, len, NEGOTO_STATIC_DIR "/%s", name);

  int ok = uw_register_transactional(ctx, d,
    create_dir,
    NULL,
    free_dirname
  );

  if (ok != 0)
    uw_error(ctx, UNLIMITED_RETRY, "Failed to register mkdir functions");

  return 0;
}


// Generate filenames
static char *gen_filename(char *section, char *name) {
  // <path>/<section>/<hash or fname>.<ext><\0>
  size_t len = sizeof(NEGOTO_STATIC_DIR) + 1 + 16 + 1 + 32 + 1 + 3 + 1;
  char *buf = malloc(len);
  snprintf(buf, len, NEGOTO_STATIC_DIR "/%s/%s", section, name);
  return buf;
}


uw_Basis_string uw_FileFfi_link(uw_context ctx, uw_Basis_string section, uw_Basis_string name) {
  size_t len = sizeof(NEGOTO_STATIC_URL) + 1 + 16 + 1 + 32 + 1 + 3 + 1;
  char *buf = uw_malloc(ctx, len);
  snprintf(buf, len, NEGOTO_STATIC_URL "/%s/%s", section, name);
  return buf;
}


uw_unit uw_FileFfi_save(uw_context ctx, uw_Basis_string section, uw_Basis_string name, uw_Basis_file file) {
  struct save_t *data = malloc(sizeof(struct save_t));
  data->ctx = ctx;
  data->name = gen_filename(section, name);
  data->size = file.data.size;
  data->file = memcpy(malloc(file.data.size), file.data.data, file.data.size);

  int ok = uw_register_transactional(ctx, data,
    save_file,
    delete_file,
    free_file
  );

  if (ok != 0)
    uw_error(ctx, UNLIMITED_RETRY, "Failed to register save file functions");

  return 0;
}


uw_unit uw_FileFfi_delete(uw_context ctx, uw_Basis_string section, uw_Basis_string name) {
  int ok = uw_register_transactional(ctx, gen_filename(section, name),
    delete_filename,
    NULL,
    free_filename
  );

  if (ok != 0)
    uw_error(ctx, UNLIMITED_RETRY, "Failed to register save file functions");

  return 0;
}
