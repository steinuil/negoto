#include <stdio.h>
#include <urweb.h>

#include "postFfi.h"


// Note: we assume that the max number of posts in a thread doesn't have more
// than 5 digits, that ought to be enough.
#define MAX_THREAD_DIGITS 5


uw_Basis_string uw_PostFfi_mkId(uw_context ctx, uw_Basis_int num) {
  char *buf = (char *)uw_malloc(ctx, 5 + MAX_THREAD_DIGITS);
  sprintf(buf, "post%lld", num);
  return buf;
}


uw_Basis_string uw_PostFfi_mkIdUrl(uw_context ctx, uw_Basis_string id) {
  char *buf = (char *)uw_malloc(ctx, 6 + MAX_THREAD_DIGITS);
  sprintf(buf, "#%s", id);
  return buf;
}


/*
uw_Basis_xbody uw_PostFfi_toHtml(uw_context ctx, uw_Basis_css_class css_spoiler, uw_Basis_css_class css_quote, uw_Basis_css_class css_backlink, uw_Basis_string curr_url, uw_Basis_string post) {
  char *buf = (char *)uw_malloc(ctx, BUF_LEN);
  int buf_pos = 0;
  int post_pos = 0;

  bool line_start = true;
  enum spoiler_state spoiler_state = SPOILER_NONE;
  int quote_level = 0;

  while (buf_pos < BUF_LEN) {
    switch (post[post_pos]) {
      // Special characters
      case '&':
        buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "&amp;");
        break;

      case '<':
        buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "&lt;");
        break;


      // Newlines
      case '\r':
        if (post[post_pos + 1] == '\n') post_pos += 1;
      case '\n':
        while (quote_level > 0) {
          buf_pos += snprintf(buf + buf_pos, zero(BUF_LEN - buf_pos), "</span>");
          quote_level -= 1;
        }

        if (spoiler_state == SPOILER_IMPROPERLY_ENDED) {
          buf_pos += snprintf(buf + buf_pos, zero(BUF_LEN - buf_pos), "</span><br>");
          spoiler_state = SPOILER_NONE;
        } else {
          buf_pos += snprintf(buf + buf_pos, zero(BUF_LEN - buf_pos), "<br>");
        }

        line_start = true;
        goto at_line_start;


      // Meme arrows
      // TODO: backlinks
      case '>':
        if (curr_url && post[post_pos + 1] == '>') {
          int digits = 0;
          int num = parse_num(post + post_pos + 2, &digits);
          if (num) {
            buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "<a href=\"%s#post%d\" class=\"%s\">%d</a>", curr_url, num, css_backlink, num);
            post_pos += 1 + digits;
            break;
          }
        }
        if (line_start && quote_level < MAX_QUOTE_LEVEL) {
          quote_level += 1;
          buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "<span class=\"%s\">", css_quote);
          goto at_line_start;
        } else {
          buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "&gt;");
        }
        break;


      // EOS
      case '\0':
        while (quote_level > 0) {
          buf_pos += snprintf(buf + buf_pos, zero(BUF_LEN - buf_pos), "</span>");
          quote_level -= 1;
        }

        if (spoiler_state != SPOILER_NONE) {
          buf_pos += snprintf(buf + buf_pos, zero(BUF_LEN - buf_pos), "</span>");
        }

        if (buf_pos >= BUF_LEN)
          goto error;

        goto ok;


      // Spoiler tags
      case '\\': {
        if (post[post_pos + 1] == '\\') {
          post_pos += 1;

          switch (spoiler_state) {
            case SPOILER_NONE: {
              buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "<span class=\"%s\">", css_spoiler);
              spoiler_state = (quote_level > 0) ? SPOILER_INSIDE_QUOTE : SPOILER_INSIDE;
              break;
            }

            case SPOILER_INSIDE: {
              if (quote_level > 0) {
                spoiler_state = SPOILER_IMPROPERLY_ENDED;
                break;
              } // else fall through
            }

            case SPOILER_INSIDE_QUOTE: {
              buf_pos += snprintf(buf + buf_pos, BUF_LEN - buf_pos, "</span>");
              spoiler_state = SPOILER_NONE;
              break;
            }

            case SPOILER_IMPROPERLY_ENDED: {
              // Ignore
              break;
            }
          }

          break;
        } // else fall through
      }


      // Any character
      default:
        buf[buf_pos] = post[post_pos];
        buf_pos += 1;
        break;

    }

    line_start = false;

at_line_start:
    post_pos += 1;
  }

error:
  uw_error(ctx, FATAL, "The post is too long");

ok:
  buf[buf_pos] = '\0';
  return buf;
}
*/
