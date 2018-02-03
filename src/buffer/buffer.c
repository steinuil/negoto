#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include <urweb.h>

#include "buffer.h"


// A buffer implementation using a linked list of buffers.


void free_buffer(void *buf, int will_retry) {
  if (buf) free(buf);
}


uw_Buffer_t uw_Buffer_create(uw_context ctx, uw_Basis_int size) {
  uw_Buffer_t buffer = malloc(sizeof(struct buffer));

  int ok = uw_register_transactional(ctx, buffer, NULL, NULL, free_buffer);
  if (ok != 0) {
    uw_error(ctx, UNLIMITED_RETRY, "Couldn't register transactional");
  }

  buffer->size = size;
  buffer->pos  = 0;
  buffer->buf  = malloc(size);
  buffer->next = NULL; // just to be sure

  return buffer;
}


uw_Basis_int uw_Buffer_length(uw_context ctx, uw_Buffer_t buf) {
  uw_Basis_int len = 0;
  for (uw_Buffer_t curr = buf; curr != NULL; curr = curr->next) {
    len += curr->pos;
  }
  return len;
}


uw_Basis_string uw_Buffer_contents(uw_context ctx, uw_Buffer_t buf) {
  size_t len = 0;

  for (uw_Buffer_t curr = buf; curr != NULL; curr = curr->next) {
    len += curr->pos;
  }

  char *str = uw_malloc(ctx, len + 1);

  if (len > 0) {
    uint64_t written = 0;
    for (uw_Buffer_t curr = buf; curr != NULL; curr = curr->next) {
      memcpy(str + written, curr->buf, curr->pos);
      written += curr->pos;
      if (written > len) { printf("WRONG %ld\n", written); }
    }
  }

  str[len] = '\0';
  return str;
}


uw_Basis_unit uw_Buffer_addChar(uw_context ctx, uw_Buffer_t buf, uw_Basis_char c) {
  uw_Buffer_t curr = buf;
  while (curr->next != NULL) curr = curr->next;

  if (curr->pos >= curr->size) {
    curr->pos = curr->size; // just in case
    uw_Buffer_t new_buf = uw_Buffer_create(ctx, curr->size);
    curr->next = new_buf;
    curr = new_buf;
  }

  curr->buf[curr->pos] = c;
  curr->pos += 1;

  return 0;
}


uw_Basis_unit uw_Buffer_addString(uw_context ctx, uw_Buffer_t buf, uw_Basis_string str) {
  uw_Buffer_t curr = buf;

  while (curr->next != NULL) curr = curr->next;

  uint64_t written;
  for (written = 0; str[written] != '\0'; written++) {
    // If the position is equal or more than the size, the current buffer is
    // full and we need a new one.
    if (curr->pos >= curr->size) {
      curr->pos = curr->size; // just in case
      uw_Buffer_t new_buf = uw_Buffer_create(ctx, curr->size);
      curr->next = new_buf;
      curr = new_buf;
    }

    curr->buf[curr->pos] = str[written];
    curr->pos += 1;
  }

  return 0;
}
