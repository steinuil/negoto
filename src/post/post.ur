style spoiler
style quote
style backlink


val id = PostFfi.mkId
val link = PostFfi.mkIdUrl


datatype text =
  | Linebreak
  | Text of Buffer.t
  | Quote of list text
  | Spoiler of list text
  | Url of Buffer.t
  | Backlink of id


(* Returns the parse tree reversed *)
fun parsePost str : transaction (list text) = let
  parse 0 []
where
  fun appText chr acc = case acc of
    | (Text b) :: rest =>
      Buffer.addChar b chr;
      return acc
    | _ =>
      buf <- Buffer.create 32;
      Buffer.addChar buf chr;
      return (Text buf :: acc)

  val len = strlen str

  fun at idx =
    if idx < len then
      Some (strsub str idx)
    else
      None

  fun parseTil end' pos acc =
    case at pos of
    | None => return (acc, pos)
    | Some c =>
      if c = end' then
        return (acc, pos + 1)
      else
        Buffer.addChar acc c;
        parseTil end' (pos + 1) acc

  fun parse pos acc =
    case at pos of
    (* EOS *)
    | None => return acc

    (* Line breaks *)
    | Some #"\n" => parse (pos + 1) (Linebreak :: acc)

    | Some #"\r" => (case at (pos + 1) of
        | Some #"\n" => parse (pos + 2) (Linebreak :: acc)
        | _          => parse (pos + 1) (Linebreak :: acc))

    (* Meme arrows *)
    | Some #">" => (case at (pos + 1) of
        | Some #">" =>
          acc <- appText #"!" acc;
          parse (pos + 1) acc
        | _ => (case acc of
              | Linebreak :: _ => parse (pos + 1) (Quote [] :: acc)
              | _              => acc <- appText #">" acc;
                                  parse (pos + 1) acc))

    | Some #"\\" => (case at (pos + 1) of
        | Some #"{" =>
          acc <- appText #"\\" acc;
          acc <- appText #"{" acc;
          parse (pos + 2) acc
        | _ =>
          acc <- appText #"\\" acc;
          parse (pos + 1) acc)

    | Some #"{" => (case (at (pos + 1), at (pos + 2), at (pos + 3), at (pos + 4)) of
        | (Some #"u", Some #"r", Some #"l", Some #" ") =>
          buf <- Buffer.create 24;
          (link, pos) <- parseTil #"}" (pos + 5) buf;
          parse pos (Url link :: acc)
        | _ =>
          acc <- appText #"{" acc;
          parse (pos + 1) acc)


    (* All other characters *)
    | Some chr =>
      acc <- appText chr acc;
      parse (pos + 1) acc
end


fun toHtml str : transaction xbody =
  post <- parsePost str;
  let
    loop post <xml/>
  where
    fun loop post acc = case post of
      | [] => return acc
      | Linebreak :: rest =>
        loop rest <xml><br/>{acc}</xml>
      | (Text buf) :: rest =>
        str <- Buffer.contents buf;
        loop rest <xml>{[str]}{acc}</xml>
      | (Quote _) :: rest =>
        loop rest <xml>QUOTE{acc}</xml>
      | (Url u) :: rest =>
        u <- Buffer.contents u;
        loop rest <xml>LINK{[u]}{acc}</xml>
      | _ => error <xml>NOT IMPLEMENTED</xml>
  end
