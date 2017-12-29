style spoiler
style quote
style backlink


fun isValid post =
  strlen post <= 2000


val id = PostFfi.mkId


fun toHtml url = PostFfi.toHtml spoiler quote backlink (show url)
