(* Managing banners *)
val addBanner : file -> transaction unit

val deleteBanner : File.handle -> transaction unit

val allBanners : transaction (list { Handle : File.handle, Link : url })

val randBanner : transaction (option url)

(** Managing themes *)
val allThemes : transaction (list { Nam      : string
                                  , Link     : url
                                  , Handle   : File.handle
                                  , TabColor : string })

val addTheme : { Nam : string, TabColor : string } -> file -> transaction unit

val editTheme : File.handle -> { Nam : string, TabColor : string } -> transaction unit

val deleteTheme : File.handle -> transaction unit

val setDefaultTheme : File.handle -> transaction unit


val setTheme : File.handle -> transaction unit
  (* Sets the theme for the current session with a cookie. *)


(* The base layout that every page should use to display content. *)
val layout : string -> css_class -> string -> xbody -> transaction page

val layoutWithSwitcher : ({ Theme : string } -> transaction page)
  -> string -> css_class -> string -> (xbody -> xbody) -> transaction page
  (* Like [layout], but also takes a theme switch handler page and a function
   * that takes the theme switcher and returns the body. *)

val navMenu : list xbody -> xbody
