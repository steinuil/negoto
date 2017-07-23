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
(* * SYNTAX:
{spoiler| Spoilered text}
{link http://example.com| Link}

function ::= [a-zA-Z][a-zA-Z-]*
*)


val sexpFunctions =
     ("b", 0)
  :: ("i", 0)
  :: ("m", 0) (* monospace *)
  :: ("u", 0) (* underline *)
  :: ("o", 0) (* overline *)
  :: ("s", 0) (* strikethrough *)
  :: ("sup", 0)
  :: ("sub", 0)
  :: ("quote", 0)
  :: ("spoiler", 0)
  :: ("link", 1)
  :: ("post", 2)
  :: []

(* TODO: Micropass to expand >>post, >>thread/post and >quote *)


(* * PASS 1 *)
datatype sexpToken =
  | LBRACE
  | RBRACE
  | BREAK
  | TEXT of string
  | FUNC of string
  | ARG of string


val show_sexpToken =
  mkShow (fn x => case x of
    | LBRACE => "LBRACE"
    | RBRACE => "RBRACE"
    | BREAK => "BREAK"
    | TEXT t => t
    | FUNC f => "FUNC " ^ f
    | ARG a => "ARG " ^ a)


fun strchar str idx =
  if strlen str <= idx
  then None
  else Some (strsub str idx)


fun shift str = strsuffix str 1
fun shift2 str = strsuffix str 2


fun appendText str acc = case acc of
  | (TEXT t) :: rest => (TEXT (t ^ str)) :: rest
  | _ => (TEXT str) :: acc


fun funcName str acc = case acc of
  | (FUNC f) :: rest => (FUNC (f ^ str)) :: rest
  | _ => (FUNC str) :: acc


fun argName str acc = case acc of
  | (ARG a) :: rest => (ARG (a ^ str)) :: rest
  | _ => (ARG str) :: acc


fun readTokens str acc = case strchar str 0 of
  | None => acc

  | Some #"\\" => (case strchar str 1 of
    | None => (appendText "\\" acc)
    | Some #"{" => readTokens (shift2 str) (appendText "{" acc)
    | Some #"}" => readTokens (shift2 str) (appendText "}" acc)
    | Some _ => readTokens (shift str) (appendText "\\" acc))

  | Some #"{" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS</xml>
    | Some #"-" => readVerbatim (shift2 str) acc
    | Some _ => readFuncStart (shift str) (LBRACE :: acc))

  | Some #"}" => readTokens (shift str) (RBRACE :: acc)

  | Some #"\n" => readTokens (shift2 str) (BREAK :: acc)

  | Some #"\r" => (case strchar str 1 of
    | None => acc
    | Some #"\n" => readTokens (shift2 str) (BREAK :: acc)
    | Some _ => readTokens (shift str) (appendText " " acc))

  | Some chr =>
    if isblank chr
    then readTokens (shift str) (appendText " " acc)
    else readTokens (shift str) (appendText (str1 chr) acc)


and readFuncStart str acc = case strchar str 0 of
  | None => error <xml>Unexpected EOS</xml>
  | Some chr =>
    if isblank chr
    then readFuncStart (shift str) acc
    else if isalpha chr
    then readFunc (shift str) (funcName (str1 chr) acc)
    else error <xml>Invalid function name</xml>


and readFunc str acc = case strchar str 0 of
  | None => error <xml>Unexpected EOS</xml>
  | Some #"}" => readTokens (shift str) (RBRACE :: acc)
  | Some #"|" => readTokens (shift str) acc
  | Some chr =>
    if isblank chr
    then readArgsStart (shift str) acc
    else if isalpha chr || chr = #"-"
    then readFunc (shift str) (funcName (str1 chr) acc)
    else error <xml>Invalid function name</xml>


and readArgsStart str acc = case strchar str 0 of
  | None => error <xml>Unexpected EOS</xml>
  | Some #"}" => readTokens (shift str) (RBRACE :: acc)
  | Some #"|" => readTokens (shift str) acc
  | Some #"\\" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS</xml>
    | Some #"}" => readArg (shift2 str) (argName "}" acc)
    | Some #"|" => readArg (shift2 str) (argName "|" acc)
    | Some _ => readArg (shift str) acc)
  | Some chr =>
    if isblank chr
    then readArgsStart (shift str) acc
    else readArg (shift str) ((ARG (str1 chr)) :: acc)


and readArg str acc = case strchar str 0 of
  | None => error <xml>Unexpected EOS</xml>
  | Some #"}" => readTokens (shift str) (RBRACE :: acc)
  | Some #"|" => readTokens (shift str) acc
  | Some #"\\" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS</xml>
    | Some #"}" => readArg (shift2 str) (argName "}" acc)
    | Some #"|" => readArg (shift2 str) (argName "|" acc)
    | Some _ => readArg (shift str) acc)
  | Some chr =>
    if isblank chr
    then readArgsStart (shift str) acc
    else readArg (shift str) (argName (str1 chr) acc)


and readVerbatim str acc = case strchar str 0 of
  | None => error <xml>Unexpected EOS</xml>

  | Some #"-" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS</xml>
    | Some #"}" => readTokens (shift2 str) acc
    | Some _ => readVerbatim (shift str) (appendText "-" acc))

  | Some #"\\" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS</xml>
    | Some #"-" => readVerbatim (shift2 str) (appendText "-" acc)
    | Some _ => readVerbatim (shift str) (appendText "\\" acc))

  | Some #"\n" => readVerbatim (shift2 str) (BREAK :: acc)

  | Some #"\r" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS</xml>
    | Some #"\n" => readVerbatim (shift2 str) (BREAK :: acc)
    | Some _ => readVerbatim (shift str) (appendText " " acc))

  | Some chr => readVerbatim (shift str) (appendText (str1 chr) acc)


fun pass1 str =
  readTokens str [] |> List.rev


fun test str =
  show (pass1 str)



(* * PASS 2 *)
(*
val max_depth = 128


fun parse ls acc depth = case ls of
  | LBRACE :: TEXT t
*)
