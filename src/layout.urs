(* Managing banners *)
val addBanner : file -> transaction unit

val deleteBanner : File.handle -> transaction unit

val allBanners : transaction (list { Handle : File.handle, Link : url })

val randBanner : transaction (option url)

(** Managing themes *)
type theme =
  { Nam      : string
  , Link     : url
  , Handle   : File.handle
  , TabColor : string }

val allThemes : transaction (list theme)

val addTheme : { Nam : string, TabColor : string, Css : file } -> transaction unit

val editTheme : string -> { TabColor : string, Css : file } -> transaction unit

val deleteTheme : string -> transaction unit

val defaultTheme : transaction theme

val setDefaultTheme : string -> transaction unit


val setTheme : string -> transaction unit
  (* Sets the theme for the current session with a cookie. *)


(* The base layout that every page should use to display content. *)
val layout : string -> css_class -> string -> xbody -> transaction page

val layoutWithSwitcher : ({ Theme : string } -> transaction page)
  -> string -> css_class -> string -> (xbody -> xbody) -> transaction page
  (* Like [layout], but also takes a theme switch handler page and a function
   * that takes the theme switcher and returns the body. *)

val navMenu : list xbody -> xbody
