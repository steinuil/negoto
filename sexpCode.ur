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


datatype lexerState = Text | FuncStart | Func | ArgStart | Arg | Verbatim


val show_lexerState = mkShow
  (fn s => case s of
    | Text => "Text"
    | FuncStart => "FuncStart"
    | Func => "Func"
    | ArgStart => "ArgStart"
    | Arg => "Arg"
    | Verbatim => "Verbatim")


fun appendText chr acc = case acc of
  | (TEXT t) :: rest => (TEXT (t ^ (str1 chr))) :: rest
  | _ => (TEXT (str1 chr)) :: acc


fun funcName chr acc = case acc of
  | (FUNC f) :: rest => (FUNC (f ^ (str1 chr))) :: rest
  | _ => (FUNC (str1 chr)) :: acc


fun argName chr acc = case acc of
  | (ARG a) :: rest => (ARG (a ^ (str1 chr))) :: rest
  | _ => (ARG (str1 chr)) :: acc


fun tokenize str = let
  loop 0 Text [] |> List.rev
where
  val len' = strlen str

  fun at idx =
    if len' <= idx then None else Some (strsub str idx)

  fun loop pos state acc = case (state, at pos) of
    | (Text, None) => acc

    | (_, None) => error <xml>Unexpected EOS in {[show state]}</xml>

    | (_, Some chr) => (case state of

      | Text => (case chr of
        | #"\\" => (case at (pos + 1) of
          | Some #"{" => loop (pos + 2) state (appendText #"{" acc)
          | Some #"}" => loop (pos + 2) state (appendText #"}" acc)
          | _         => loop (pos + 1) state (appendText #"\\" acc))
        | #"{"  => (case at (pos + 1) of
          | Some #"-" => loop (pos + 2) Verbatim acc
          | _         => loop (pos + 1) FuncStart (LBRACE :: acc))
        | #"}"  => loop (pos + 1) state (RBRACE :: acc)
        | #"\n" => loop (pos + 1) state (BREAK :: acc)
        | #"\r" => (case at (pos + 1) of
          | Some #"\n" => loop (pos + 2) state (BREAK :: acc)
          | Some _     => loop (pos + 1) state (appendText #" " acc)
          | None => acc)
        | _ =>
          (if isblank chr then
            loop (pos + 1) state (appendText #" " acc)
          else
            loop (pos + 1) state (appendText chr acc)))

      | Verbatim => (case chr of
        | #"-"  => (case at (pos + 1) of
          | Some #"}" => loop (pos + 2) Text acc
          | _ => loop (pos + 1) state acc)
        | #"\\" => (case at (pos + 1) of
          | Some #"-" => loop (pos + 2) state (appendText #"-" acc)
          | _ => loop (pos + 1) state (appendText #"-" acc))
        | #"\n" => loop (pos + 1) state (BREAK :: acc)
        | #"\r" => (case at (pos + 1) of
          | Some #"\n" => loop (pos + 2) state (BREAK :: acc)
          | _ => loop (pos + 1) state (appendText #" " acc))
        | _ => loop (pos + 1) state (appendText chr acc))

      | FuncStart =>
        (if isblank chr then
          loop (pos + 1) state acc
        else if isalpha chr then
          loop (pos + 1) Func (funcName chr acc)
        else
          error <xml>Invalid function name</xml>)

      | Func => (case chr of
        | #"}" => loop (pos + 1) Text (RBRACE :: acc)
        | #"|" => loop (pos + 1) Text acc
        | _ =>
          (if isblank chr then
            loop (pos + 1) ArgStart acc
          else if isalpha chr then
            loop (pos + 1) state (funcName chr acc)
          else
            error <xml>Invalid function name</xml>))

      | ArgStart => (case chr of
        | #"}"  => loop (pos + 1) Text (RBRACE :: acc)
        | #"|"  => loop (pos + 1) Text acc
        | #"\\" => (case at (pos + 1) of
          | Some #"}" => loop (pos + 2) Arg (argName #"}" acc)
          | Some #"|" => loop (pos + 2) Arg (argName #"|" acc)
          | _ => loop (pos + 1) Arg (argName #"\\" acc))
        | _ =>
          (if isblank chr then
            loop (pos + 1) ArgStart acc
          else
            loop (pos + 1) Arg ((ARG (str1 chr)) :: acc)))

      | Arg => (case chr of
        | #"}"  => loop (pos + 1) Text (RBRACE :: acc)
        | #"|"  => loop (pos + 1) Text acc
        | #"\\" => (case at (pos + 1) of
          | Some #"}" => loop (pos + 2) Arg (argName #"}" acc)
          | Some #"|" => loop (pos + 2) Arg (argName #"|" acc)
          | _ => loop (pos + 1) state (argName #"\\" acc))
        | _ =>
          if isblank chr then
            loop (pos + 1) ArgStart acc
          else
            loop (pos + 1) state (argName chr acc)))
end


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
