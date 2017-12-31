type newsItem =
  { Title  : string
  , Author : string
  , Time   : time
  , Body   : string }

val news : transaction (list newsItem)
