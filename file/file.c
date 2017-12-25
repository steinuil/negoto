#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <urweb.h>


struct args {
  uw_context ctx;
  uw_Basis_string name;
  char *file;
  size_t size;
};


static void free_args(void *data, int will_retry) {
  struct args *a = data;
  if (a->name) free(a->name);
  if (a->file) free(a->file);
  free(a);
}


static void free_filename(void *data, int will_retry) {
  if (data) free(data);
}


static void save_file(void *data) {
  struct args *a = data;

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


static void delete_file(void *data) {
  struct args *a = data;

  if (access(a->name, F_OK) == 0)
    unlink(a->name);
}


uw_unit uw_File_save(uw_context ctx, uw_Basis_string name, uw_Basis_file file) {
  struct args *data = (struct args *)malloc(sizeof(struct args));
  data->ctx = ctx;
  data->name = strdup(name);
  data->size = file.data.size;
  data->file = (char *)memcpy(malloc(file.data.size), file.data.data, file.data.size);

  int ok = uw_register_transactional(ctx, data,
    save_file,
    delete_file,
    free_args
  );

  if (ok != 0)
    uw_error(ctx, UNLIMITED_RETRY, "Failed to register save file functions");

  return 0;
}


uw_unit uw_File_delete(uw_context ctx, uw_Basis_string name) {
  int ok = uw_register_transactional(ctx, strdup(name),
      delete_file, NULL, free_filename);

  if (ok != 0)
    uw_error(ctx, UNLIMITED_RETRY, "Failed to register delete file functions");

  return 0;
}
