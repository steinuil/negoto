val id = PostFfi.mkId
val link = PostFfi.mkIdUrl


datatype text =
  | Linebreak
  | Text of Buffer.t
  | Quote of Buffer.t
  | Spoiler of list text
  | Url of Buffer.t
  | Backlink of id


(* Returns the parse tree reversed *)
fun parsePost { UrlAllowed = urlAllowed } str : transaction (list text) = let
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


  fun ats idx len' =
    if idx + len' < len then
      Some (substring str idx len')
    else
      None


  fun parseTil end' pos acc =
    case at pos of
    | None => return (acc, pos)
    | Some c =>
      if c = end' then
        return (acc, pos)
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
          (*  *)
          acc <- appText #"!" acc;
          parse (pos + 1) acc
        | _ => (case acc of
            | Linebreak :: _ =>
              (* @Hack we need a better parsing function *)
              buf <- Buffer.create 48;
              (buf, pos) <- parseTil #"\n" (pos + 1) buf;
              parse pos (Quote buf :: acc)
            | _ =>
              acc <- appText #">" acc;
              parse (pos + 1) acc))

    | Some #"\\" => (case at (pos + 1) of
        | Some #"{" =>
          acc <- appText #"\\" acc;
          acc <- appText #"{" acc;
          parse (pos + 2) acc
        | _ =>
          acc <- appText #"\\" acc;
          parse (pos + 1) acc)

    | Some #"{" => (case (ats (pos + 1) 4, urlAllowed) of
        | (Some "url ", True) =>
          buf <- Buffer.create 24;
          (link, pos) <- parseTil #"}" (pos + 5) buf;
          parse (pos + 1) (Url link :: acc)
        | _ =>
          acc <- appText #"{" acc;
          parse (pos + 1) acc)

    (* All other characters *)
    | Some chr =>
      acc <- appText chr acc;
      parse (pos + 1) acc
end


open Styles

style quote
style spoiler
style backlink


fun toHtml str : transaction xbody =
  post <- parsePost { UrlAllowed = False } str;
  let
    loop post <xml/>
  where
    fun loop post acc = case post of
      | Linebreak :: rest =>
        loop rest <xml><br/>{acc}</xml>
      | (Text buf) :: rest =>
        str <- Buffer.contents buf;
        loop rest <xml>{[str]}{acc}</xml>
      | (Quote q) :: rest =>
        q <- Buffer.contents q;
        loop rest <xml><span class="quote">{[q]}</span>{acc}</xml>
      | (Url u) :: rest =>
        u <- Buffer.contents u;
        loop rest <xml><a class="ulink">{[u]}</a>{acc}</xml>
      | [] =>
        return acc
      | _ =>
        error <xml>NOT IMPLEMENTED</xml>
  end
