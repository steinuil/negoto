#include <stdio.h>

#include <urweb.h>
#include <types.h>

uw_unit uw_Save_save(uw_context ctx, uw_Basis_string name, uw_Basis_file file) {
  puts(file.name);
  puts(file.type);

  FILE *f = fopen(name, "w");
  if (f == NULL)
    printf("error fug\n");

  size_t written = fwrite(file.data.data, sizeof(char), file.data.size, f);
  if (written < sizeof(char) / file.data.size)
    printf("errorf'g\n");

  int ok = fclose(f);
  if (ok != 0)
    printf("error closing");

  return 0;
}
