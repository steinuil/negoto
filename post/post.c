#include <stdio.h>

#include <urweb.h>

#include "post.h"


static const int max_buf_length = 3000;

uw_Basis_bool uw_Post_isValid(uw_context ctx, uw_Basis_string post) {
  int length = 0;

  for (int pos = 0; pos < max_buf_length; pos += 1) {
    switch (post[pos]) {
      case '\0':
        goto ok;

      case '<':
      case '>':
        length += 4;
        break;

      case '&':
        length += 5;
        break;

      case '\r':
        if (post[pos + 1] == '\n')
          pos += 1;
        // fall through

      case '\n':
        length += 4;
        break;

      default:
        length += 1;
        break;
    }
  }

  return uw_Basis_False;

ok:
  return uw_Basis_True;
}


uw_Basis_xbody uw_Post_toHtml(uw_context ctx, uw_Basis_string post) {
  char *buf = (char *)uw_malloc(ctx, max_buf_length);
  int post_pos = 0;
  int buf_pos = 0;

  while (buf_pos < max_buf_length) {
    switch (post[post_pos]) {
      case '\0':
        goto ok;

      case '>':
        // TODO: implement quotes and backquotes
        buf_pos += sprintf(buf + buf_pos, "&gt;");
        break;

      case '&':
        buf_pos += sprintf(buf + buf_pos, "&amp;");
        break;

      case '<':
        buf_pos += sprintf(buf + buf_pos, "&lt;");
        break;

      // FIXME: multiple newlines at the beginning or end
      // TODO: paragraphs
      case '\n':
        buf_pos += sprintf(buf + buf_pos, "<br>");
        break;

      case '\r':
        buf_pos += sprintf(buf + buf_pos, "<br>");

        if (post[post_pos + 1] == '\n')
          post_pos += 1;
        break;

      default:
        buf[buf_pos] = post[post_pos];
        buf_pos += 1;
        break;
    }

    post_pos += 1;
  }

  uw_error(ctx, FATAL, "the post hath problems");

ok:
  buf[buf_pos] = '\0';

  return buf;
}
