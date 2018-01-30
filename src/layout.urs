(** Managing themes *)
type theme =
  { Nam      : string
  , Filename : string
  , TabColor : string }

val allThemes : transaction (list theme)

val addTheme : theme -> file -> transaction unit

val editTheme : theme -> transaction unit

val deleteTheme : string -> transaction unit

val setDefaultTheme : string -> transaction unit


val setTheme : string -> transaction unit
  (* Sets the theme for the current session with a cookie. *)


(* The base layout that every page should use to display content. *)
val layout : string -> css_class -> string -> xbody -> transaction page

val layoutWithSwitcher : ({ Theme : string } -> transaction page)
  -> string -> css_class -> string -> (xbody -> xbody) -> transaction page
  (* Like [layout], but also takes a theme switch handler page and a function
   * that takes the theme switcher and returns the body. *)
