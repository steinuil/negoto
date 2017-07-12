datatype sexpToken =
  | Open of string
  | Close of string
  | Text of string



(*
val sexpFunctions : xbody -> xbody =
  ("b",       fn x => <xml><strong>{x}</strong></xml>) ::
  ("i",       fn x => <xml><em>{x}</em></xml>) ::
  ("sup",     fn x => <xml><sup>{x}</sup></xml>) ::
  ("sub",     fn x => <xml><sub>{x}</sub></xml>) ::
  ("m",       fn x => <xml><tt>{x}</tt></xml>) ::
  ("u",       fn x => <xml><span class="text-underline">{x}</span></xml>) ::
  ("o",       fn x => <xml><span class="text-overline">{x}</span></xml>) ::
  ("s",       fn x => <xml><span class="text-strikethrough">{x}</span></xml>) ::
  ("quote",   fn x => <xml><span class="text-quote">{x}</span></xml>) ::
  ("spoiler", fn x => <xml><span class="text-spoiler">{x}</span></xml>) ::
  []
*)

style text_underline
style text_overline
style text_strikethrough
style text_spoiler
style text_quote

