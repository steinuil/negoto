style spoiler
style quote
style backlink


fun isValid post =
  strlen post <= 2000


val id = PostFfi.mkId


val link = PostFfi.mkIdUrl


fun toHtml url = PostFfi.toHtml spoiler quote backlink (Some (show url))


val toHtml' = PostFfi.toHtml spoiler quote backlink None




datatype text =
  | Linebreak
  | Text of Buffer.t
  | Quote of list text
  | Spoiler of list text
  | Backlink of id


(* Returns the list reversed *)
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
    | None => return acc

    (* Handle line breaks *)
    | Some #"\n" => parseInitial (pos + 1) (Linebreak :: acc)

    | Some #"\r" => (case at (pos + 1) of
        | Some #"\n" => parseInitial (pos + 2) (Linebreak :: acc)
        | _          => parseInitial (pos + 1) (Linebreak :: acc))

    | Some chr =>
      acc <- appText chr acc;
      parseInitial (pos + 1) acc
end


fun toHtml'' str : transaction xbody =
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
      | _ => error <xml>NOT SUPPORTED YET</xml>
  end
