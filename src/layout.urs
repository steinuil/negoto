type theme =
  { Nam      : string
  , Filename : string
  , TabColor : string }

val allThemes : transaction (list theme)

val addTheme : theme -> file -> transaction unit

val deleteTheme : string -> transaction unit

val setDefaultTheme : string -> transaction unit

val layout : string -> css_class -> string -> xbody -> transaction page

val setTheme : string -> transaction unit

val layoutWithSwitcher : ({ Theme : string } -> transaction page)
  -> string -> css_class -> string -> (xbody -> xbody) -> transaction page
  (* Like [layout], but takes a theme switch handler page and a function
   * that takes the theme switcher and returns the body. *)
