#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <sys/wait.h>
#include <openssl/md5.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <urweb.h>
#include <negoto_config.h>

#include "fileFfi.h"


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


/*
// Move the existing file to a temporary location
uw_unit uw_FileFfi_saveAsset
*/


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



struct image_t {
  uw_context ctx;
  uw_Basis_string name;
  uw_Basis_string thumb;
  char *file;
  size_t size;
};


static void free_image_data(void *d, int will_retry) {
  if (d) {
    struct image_t *data = (struct image_t *)d;
    if (data->name) free(data->name);
    if (data->thumb) free(data->thumb);
    if (data->file) free(data->file);
    free(data);
  }
}


static void delete_image_and_thumbnail(void *d) {
  struct image_t *data = (struct image_t *)d;

  delete_filename((void *)data->name);
  delete_filename((void *)data->thumb);
}


static void save_resize_image(void *d) {
  struct image_t *data = (struct image_t *)d;

  FILE *f = fopen(data->name, "w");
  if (!f) {
    uw_set_error_message(data->ctx, "Failed to open %s", data->name);
    return;
  }

  size_t written = fwrite(data->file, sizeof(char), data->size, f);
  if (written < sizeof(char) / data->size) {
    uw_set_error_message(data->ctx, "Failed to write %s", data->name);
  }

  int ok = fclose(f);
  if (ok != 0) {
    uw_set_error_message(data->ctx, "Failed to close %s", data->name);
  }

  if (uw_has_error(data->ctx)) return;

  pid_t pid = fork();
  if (pid == 0) {
    char name[sizeof(NEGOTO_STATIC_DIR) + 1 + 16 + 1 + 32 + 1 + 3 + 3 + 1];
    strcpy(name, data->name);
    strcat(name, "[0]");

    char *const argv[] = {
      "convert", name,
      "-strip",
      "-quality", "70%",
      "-resize", NEGOTO_THUMB_SIZE ">",
      data->thumb, NULL
    };
    execvp("convert", argv);
  }

  if (pid < 0) {
    uw_set_error_message(data->ctx, "Failed to fork to exec convert");
    return;
  }

  int status;
  wait(&status);

  if (status != 0)
    uw_set_error_message(data->ctx, "Failed to resize image %s", data->name);
}


uw_unit uw_FileFfi_saveImage(
  uw_context ctx,
  uw_Basis_string section, uw_Basis_string dest_section,
  uw_Basis_string fname, uw_Basis_string dest_fname,
  uw_Basis_file file
) {
  struct image_t *data = malloc(sizeof (struct image_t));
  data->ctx = ctx;
  data->name = gen_filename(section, fname);
  data->thumb = gen_filename(dest_section, dest_fname);
  data->file = memcpy(malloc(file.data.size), file.data.data, file.data.size);
  data->size = file.data.size;

  int ok = uw_register_transactional(ctx, data,
    save_resize_image,
    delete_image_and_thumbnail,
    free_image_data
  );

  if (ok != 0)
    uw_error(ctx, UNLIMITED_RETRY, "Failed to register resize file functions");

  return 0;
}
