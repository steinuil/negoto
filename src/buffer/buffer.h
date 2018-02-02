#pragma once

#include <stdint.h>
#include <urweb.h>

struct buffer {
  size_t size;
  uint16_t pos;
  char *buf;
  struct buffer *next;
};

typedef struct buffer* uw_Buffer_t;

uw_Buffer_t     uw_Buffer_create(uw_context, uw_Basis_int size);
uw_Basis_int    uw_Buffer_length(uw_context, uw_Buffer_t buffer);
uw_Basis_string uw_Buffer_contents(uw_context, uw_Buffer_t buffer);
uw_Basis_unit   uw_Buffer_addString(uw_context, uw_Buffer_t buffer, uw_Basis_string str);
