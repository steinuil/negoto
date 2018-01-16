type readme =
  { Body    : string
  , Updated : time }

val readme : transaction readme

type newsItem =
  { Title  : string
  , Author : string
  , Time   : time
  , Body   : string }

val news : transaction (list newsItem)

(* Admin actions *)
val boards : unit -> transaction page

val board : string -> transaction page

val login : unit -> transaction page
