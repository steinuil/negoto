style spoiler
style quote
style backlink


fun isValid post =
  strlen post <= 2000


val id = PostFfi.mkId


val link = PostFfi.mkIdUrl


fun toHtml url = PostFfi.toHtml spoiler quote backlink (Some (show url))


val toHtml' = PostFfi.toHtml spoiler quote backlink None
