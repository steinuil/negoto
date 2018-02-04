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
  | Backlink of id


(* Returns the parse tree reversed *)
fun parsePost str : transaction (list text) = let
  parseInitial 0 []
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

  fun parseInitial pos acc = case at pos of
    (* EOS *)
    | None => return acc

    (* Line breaks *)
    | Some #"\n" => parseInitial (pos + 1) (Linebreak :: acc)

    | Some #"\r" => (case at (pos + 1) of
        | Some #"\n" => parseInitial (pos + 2) (Linebreak :: acc)
        | _          => parseInitial (pos + 1) (Linebreak :: acc))

    (* Meme arrows *)
    | Some #">" => (case at (pos + 1) of
        | Some #">" =>
          acc <- appText #"!" acc;
          parseInitial (pos + 1) acc
        | _ => (case acc of
            | Linebreak :: _ => parseInitial (pos + 1) (Quote [] :: acc)
            | _              => acc <- appText #">" acc;
                                parseInitial (pos + 1) acc))

    (* All other characters *)
    | Some chr =>
      acc <- appText chr acc;
      parseInitial (pos + 1) acc
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
      | _ => error <xml>NOT IMPLEMENTED</xml>
  end
