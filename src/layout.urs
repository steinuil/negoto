val addTheme : string -> string -> string -> transaction unit

val layout : string -> css_class -> string -> xbody -> transaction page

val setTheme : string -> transaction unit

val layoutWithSwitcher : ({ Theme : string } -> transaction page)
  -> string -> css_class -> string -> (xbody -> xbody) -> transaction page
  (* Like [layout], but takes a theme switch handler page and a function
   * that takes the theme switcher and returns the body. *)
