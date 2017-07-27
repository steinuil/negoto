(* TODO: Micropass to expand >>post, >>thread/post and >quote *)

(* Fibonacci buttsort implementation:
{b|{i|{o|F}{u|I}{o|B}{u|O}{o|N}{u|A}{o|C}{u|C}{o|I} {u|B}{o|U}{u|T}{o|T}{u|S}{o|O}{u|R}{o|T}}}

 * Different spec:
{sup|F}{sub|{o|B}}{sup|I}{sub|{o|U}}{sup|B}{sub|{o|T}}{sup|O}{sub|{o|T}}{sup|N}{sub|{o|S}}{sup|A}{sub|{o|O}}{sup|C}{sub|{o|R}}{sup|C}{sub|{o|T}}{sup|I}
*)


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
  | Some #"\n" => readTokens (shift str) (BREAK :: acc)
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
  | None => error <xml>Unexpected EOS while reading arguments {[str]}</xml>
  | Some #"}" => readTokens (shift str) (RBRACE :: acc)
  | Some #"|" => readTokens (shift str) acc
  | Some #"\\" => (case strchar str 1 of
    | None => error <xml>Unexpected EOS while reading arguments</xml>
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


fun tokenize str =
  readTokens str [] |> List.rev



(* * PASS 2 *)
val max_depth = 128


datatype sexpNode =
  | Text of string
  | Linebreak
  | Tag of string * list string * list sexpNode


fun string_of_sexpNode n = case n of
  | Text t => t
  | Linebreak => "LINEBREAK"
  | Tag (t, args, text) =>
    "{" ^ t ^ " " ^ show args ^ "|" ^ show (List.mp string_of_sexpNode text) ^ "}"

val show_sexpNode =
  mkShow string_of_sexpNode



fun parseText ls acc depth =
  if depth > max_depth
  then error <xml>Max tag depth reached</xml>
  else case ls of
    | [] =>
      if depth = 0
      then (List.rev acc, [])
      else error <xml>Unbalanced left brace</xml>
    | RBRACE :: rest =>
      if depth > 0
      then (List.rev acc, rest)
      else error <xml>Unbalanced right brace</xml>
    | (TEXT t) :: rst => parseText rst ((Text t) :: acc) depth
    | BREAK :: rst => parseText rst (Linebreak :: acc) depth
    | LBRACE :: (FUNC f) :: rst => let
        val (args, rst) = parseArgs rst []

        val (textPart, rst) = parseText rst [] (depth + 1)
      in
        parseText rst ((Tag (f, args, textPart)) :: acc) depth
      end
    | _ => error <xml>Unexpected sequence of tokens</xml>


and parseArgs ls acc = case ls of
  | [] => error <xml>Unexpected EOS while parsing arguments</xml>
  | (ARG a) :: rst => parseArgs rst (a :: acc)
  | (FUNC f) :: rst => error <xml>Unexpected function</xml>
  | _ => (List.rev acc, ls)


fun parse ls = let
  val (parsed, _) = parseText ls [] 0
in
  parsed
end



(* * To XML  *)
style underline
style overline
style striken
style spoiler
style quote
style ref


fun sexpTag t (ls : list string) (txt : xbody) = case ls of
  | [] => (case t of
    | "b" => <xml><strong>{txt}</strong></xml>
    | "i" => <xml><em>{txt}</em></xml>
    | "m" => <xml><tt>{txt}</tt></xml>
    | "u" => <xml><span class="underline">{txt}</span></xml>
    | "o" => <xml><span class="overline">{txt}</span></xml>
    | "s" => <xml><span class="striken">{txt}</span></xml>
    | "sup" => <xml><sup>{txt}</sup></xml>
    | "sub" => <xml><sub>{txt}</sub></xml>
    | "quote" => <xml><span class="quote">&gt;{txt}</span></xml>
    | "spoiler" => <xml><span class="spoiler">{txt}</span></xml>
    | _ => error <xml>No such tag {[t]}/0</xml>)

  | arg1 :: [] => (case t of
    | "link" =>
      <xml><a href={bless arg1}>{txt}</a></xml>
    | _ => error <xml>No such tag {[t]}/1</xml>)

  | arg1 :: arg2 :: [] => (case t of
    | "post" =>
      <xml><span class="ref">&gt;&gt;{[arg2]}</span></xml>
    | _ => error <xml>No such tag {[t]}/2</xml>)

  | _ => error <xml>No tag with such arity</xml>


fun xml_of_sexpNodes ls =
  List.mapX (fn x => case x of
    | Text t => <xml>{[t]}</xml>
    | Linebreak => <xml><br/></xml>
    | Tag (tag, args, text) =>
      sexpTag tag args (xml_of_sexpNodes text)) ls


fun xml_of_sexpCode str =
  tokenize str |> parse |> xml_of_sexpNodes
