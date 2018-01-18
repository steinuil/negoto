(* TODO: manage themes with a table instead
table themes :
  { Nam      : string
  , Filename : string
  , TabColor : string }
*)


type themeInfo =
  { Nam      : string
  , Filename : string
  , TabColor : string }


(* To add new themes, add its name to the themes datatype
 * and its info in InfoOfTheme.
 * The TabColor of a theme should be the same as $bg-dark in the SASS file. *)
datatype themes =
  | Yotsuba
  | YotsubaB


fun infoOfTheme theme = case theme of
  | Yotsuba =>
    { Nam = "Yotsuba"
    , Filename = "yotsuba"
    , TabColor = "#FFD6AE" }

  | YotsubaB =>
    { Nam = "Yotsuba B"
    , Filename = "yotsuba-b"
    , TabColor = "#D0D5E7" }


(* Change the default theme here. *)
val defaultTheme = Yotsuba


cookie theme : themes


val show_theme =
  mkShow (fn x => (infoOfTheme x).Nam)


val read_theme =
  let fun reader theme = case theme of
    | "Yotsuba" => Some Yotsuba
    | "Yotsuba B" => Some YotsubaB
    | _ => None
  in
    mkRead
      (fn x => case reader x of Some x => x | None =>
        error <xml>Invalid theme: {[x]}</xml>)
      reader
  end


val allThemes = Yotsuba :: YotsubaB :: []


val getTheme =
  theme' <- getCookie theme;
  let val { Filename = css, TabColor = color, ... } =
    infoOfTheme <|
      case theme' of
      | Some t => t
      | None => defaultTheme
  in
    return (bless ("/" ^ css ^ ".css"), color)
  end


  (*
fun themePicker url' =
  theme' <- getCookie theme;
  return <xml><form>
    <select{#Theme}>
      {List.mapX (fn t =>
        <xml><option value={show theme'} selected={t = theme'}/></xml>)
      allThemes}
    </select>
    <submit value="Set theme" action={url'}/>
  </form></xml>


fun setTheme { Theme = t } =
  setCookie theme (readError t)
  *)


open Tags

fun layout [a] (_ : show a) (title' : a) class' desc body' =
  (theme, color) <- getTheme;
  return <xml>
    <head>
      <meta charset="utf-8"/>
      <title>{[title']}</title>
      <meta name="description" content={desc}/>
      <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
      <meta name="theme-color" content={color}/>
      <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>
      <!-- <link rel="icon" type="image/png" href=""/> -->
      <!-- <meta name="msapplication-config" content="browserconfig.xml" /> -->
      <link rel="stylesheet" type="text/css" href={theme}/>
    </head>
    <body class={class'}>{body'}</body>
  </xml>
