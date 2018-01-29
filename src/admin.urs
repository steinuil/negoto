val siteName : transaction string

val links : transaction (list { Link : url, Nam : string })

val readme : transaction string

type newsItem =
  { Title  : string
  , Author : string
  , Time   : time
  , Body   : string }

val news : transaction (list newsItem)

(* Admin actions *)
val front : unit -> transaction page
