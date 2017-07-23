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

style text_underline
style text_overline
style text_strikethrough
style text_spoiler
style text_quote
*)

(* TODO: Micropass to expand >>post, >>thread/post and >quote *)


(* * LEXER *)
datatype sexpToken =
  | LBRACE
  | RBRACE
  | TEXT of string


val show_sexpToken =
  mkShow (fn x => case x of
    | LBRACE => "LBRACE"
    | RBRACE => "RBRACE"
    | TEXT t => t)


fun substring' str start endd =
  if strlen str < start + endd
  then ""
  else substring str start endd


fun peek str =
  substring' str 0 1


fun peek2 str =
  substring' str 0 2


fun appendText str acc = case acc of
  | (TEXT t) :: rest => (TEXT (t ^ str)) :: rest
  | _ => (TEXT str) :: acc


(* Preserve whitespace and ignore unbalanced braces *)
and readVerbatim str acc = case peek2 str of
  | ""   => error <xml>reached EOF inside verbatim</xml>

  | "-}" => readTokens (strsuffix str 2) (TEXT "" :: acc)
  
  | x => readVerbatim (strsuffix str 1) (appendText (peek str) acc)


and readTokens str acc =
  case peek str of
    | ""  => acc

    | "\\" => (case peek (strsuffix str 1) of
      | "{" => readTokens (strsuffix str 2) (appendText "{" acc)
      | "}" => readTokens (strsuffix str 2) (appendText "}" acc)
      | x   => readTokens (strsuffix str 1) (appendText "\\" acc))

    | "{" => (case peek2 str of
      | "{-" => readVerbatim (strsuffix str 2) acc
      | _    => readTokens (strsuffix str 1) (LBRACE :: acc))

    | "}" => readTokens (strsuffix str 1) (RBRACE :: acc)

    | x =>
      (* Text tokens are separated by whitespace characters *)
      if isblank (strsub x 0)
      then readTokens (strsuffix str 1) ((TEXT "") :: acc)
      else readTokens (strsuffix str 1) (appendText x acc)


(* Strip empty text tags *)
fun tokenize str =
  readTokens str []
    |> List.foldl (fn x acc => case x of TEXT "" => acc | t => t :: acc) []


fun test str =
  show (tokenize str)



(* * PARSER *)
