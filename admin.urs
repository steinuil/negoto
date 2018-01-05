type newsItem =
  { Title  : string
  , Author : string
  , Time   : time
  , Body   : string }

val news : transaction (list newsItem)

(* Admin actions *)
val boards : unit -> transaction page

val board : string -> transaction page
