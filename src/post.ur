datatype text =
  | Linebreak
  | Text of Buffer.t
  | Quote of list text
  | Spoiler of list text
  | Url of Buffer.t
  | Backlink of int


datatype parserState = Init | QuoteS


(* Returns the parse tree reversed *)
fun parsePost { UrlAllowed = urlAllowed } str : transaction (list text) = let
  (post, _) <- parse' Init 0 [];
  return post
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


  fun parseBacklink pos acc =
    if acc >= 10000 then return (acc, pos) else
    case at pos of
    | None => Some (acc, pos)
    | Some chr =>
      if chr >= #"0" && chr <= #"9" then
        parseBacklink (pos + 1) ((acc * 10) + (ord chr - 48))
      else if acc = 0 then
        None
      else
        Some (acc, pos)


  fun parse' state pos acc =
    case (state, at pos) of
    | (_, None) =>
      return (acc, pos)

    | (QuoteS, Some #"\n") =>
      return (acc, pos)

    | (_, Some #"\n") =>
      parse' Init (pos + 1) (Linebreak :: acc)

    | (Init, Some #">") =>
      if at (pos + 1) = Some #">" then
        case parseBacklink (pos + 2) 0 of
        | None =>
          acc <- appText #">" acc;
          acc <- appText #">" acc;
          parse' Init (pos + 2) acc
        | Some (id, pos) =>
          parse' Init pos (Backlink id :: acc)
      else
        (case acc of
        | Linebreak :: _ =>
          (q, pos) <- parse' QuoteS (pos + 1) [];
          parse' Init pos (Quote q :: acc)
        | _ =>
          acc <- appText #">" acc;
          parse' Init (pos + 1) acc)

    | (state, Some #"\\") =>
      if at (pos + 1) = Some #"{" then
        acc <- appText #"{" acc;
        parse' state (pos + 2) acc
      else
        acc <- appText #"\\" acc;
        parse' state (pos + 1) acc

    | (state, Some #"{") => (case (ats (pos + 1) 4, urlAllowed) of
      | (Some "url ", True) =>
        buf <- Buffer.create 24;
        (link, pos) <- parseTil #"}" (pos + 5) buf;
        parse' state (pos + 1) (Url link :: acc)
      | _ =>
        acc <- appText #"{" acc;
        parse' state (pos + 1) acc)

    | (state, Some chr) =>
      acc <- appText chr acc;
      parse' state (pos + 1) acc


      (*
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
      *)
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
        x <- loop q <xml/>;
        loop rest <xml><span class="quote">{x}</span>{acc}</xml>
      | (Backlink n) :: rest =>
        loop rest <xml><a class="backlink" href={PostFfi.mkIdUrl (PostFfi.mkId n)}>{[n]}</a>{acc}</xml>
      | (Url u) :: rest =>
        u <- Buffer.contents u;
        loop rest <xml><a class="ulink">{[u]}</a>{acc}</xml>
      | [] =>
        return acc
      | _ =>
        error <xml>NOT IMPLEMENTED</xml>
  end


val id = PostFfi.mkId
val link = PostFfi.mkIdUrl
