(* Banners management (maybe I should move this elsewhere) *)
table banners :
  { Link   : url
  , Handle : File.handle }
  PRIMARY KEY Handle


fun addBanner banner =
  (handle, link) <- File.Banner.save banner;
  dml (INSERT INTO banners (Handle, Link) VALUES ({[handle]}, {[link]}))


val allBanners =
  queryL1 (SELECT * FROM banners)


val randBanner =
  Util.oneColOpt [#Link] (SELECT banners.Link FROM banners
                          ORDER BY RANDOM() LIMIT 1)


val deleteBanner handle =
  dml (DELETE FROM banners WHERE Handle = {[handle]});
  File.Banner.delete handle



(* Themes management *)
table themes :
  { Nam      : string
  , Link     : url
  , Handle   : File.handle
  , TabColor : string }
  PRIMARY KEY Nam


type theme =
  { Nam      : string
  , Link     : url
  , Handle   : File.handle
  , TabColor : string }


cookie selectedTheme : string


fun addTheme { Nam = name, TabColor = color, Css = file } =
  (handle, link) <- File.Css.save file;
  dml (INSERT INTO themes (Nam, Link, Handle, TabColor)
       VALUES ({[name]}, {[link]}, {[handle]}, {[color]}))


fun editTheme name { TabColor = color, Css = file } =
  { Handle = handle } <- oneRow1 (SELECT themes.Handle FROM themes
                                  WHERE themes.Nam = {[name]});
  File.Css.delete handle;
  (handle, link) <- File.Css.save file;
  dml (UPDATE themes
       SET TabColor = {[color]}, Handle = {[handle]}, Link = {[link]}
       WHERE Nam = {[name]})


fun deleteTheme name =
  def <- KeyVal.unsafeGet "defaultTheme";
  if name <> def then
    { Handle = handle } <- oneRow1 (SELECT themes.Handle FROM themes
                                    WHERE themes.Nam = {[name]});
    dml (DELETE FROM themes WHERE Nam = {[name]});
    File.Css.delete handle
  else
    error <xml>You can't delete the default theme</xml>


val allThemes =
  queryL1 (SELECT * FROM themes)


val defaultTheme : transaction theme =
  def <- KeyVal.unsafeGet "defaultTheme";
  oneRow1 (SELECT * FROM themes WHERE themes.Nam = {[def]})


fun setDefaultTheme name =
  exists <- hasRows (SELECT 1 FROM themes WHERE themes.Nam = {[name]});
  if exists then
    KeyVal.set "defaultTheme" name
  else
    error <xml>The theme {[name]} doesn't exist in the database</xml>


val currentSessionTheme =
  selected <- getCookie selectedTheme;
  case selected of
  | None =>
    defaultTheme
  | Some t =>
    t <- oneOrNoRows1 (SELECT * FROM themes WHERE themes.Nam = {[t]});
    case t of
    | None =>
      clearCookie selectedTheme;
      defaultTheme
    | Some t =>
      return t




      (*



type theme = { Nam : string, TabColor : string }


cookie selectedTheme : File.handle


fun addTheme { Nam = name, TabColor = tabColor } file =
  (handle, link) <- File.Css.save file;
  dml (INSERT INTO themes (Nam, Link, Handle, TabColor)
       VALUES ({[name]}, {[link]}, {[handle]}, {[tabColor]}))


fun deleteTheme handle =
  def <- KeyVal.unsafeGet "defaultTheme";
  if handle <> def then
    dml (DELETE FROM themes WHERE Handle = {[handle]});
    File.Css.delete handle
  else
    error <xml>You can't delete the default theme!</xml>


fun editTheme handle { TabColor = tabColor, Nam = name } =
  dml (UPDATE themes SET TabColor = {[tabColor]}, Nam = {[name]}
       WHERE Handle = {[handle]})


val allThemes =
  query (SELECT * FROM themes) (fn { Themes = t } acc => return ((t -- #Link) :: acc)) []


  (*
fun themeOfId handle =
  oneOrNoRows1 (SELECT * FROM themes WHERE themes.handle = {[handle]})
  *)

(* *)


val getDefaultTheme =
  def <- KeyVal.unsafeGet "defaultTheme";
  oneRow1 (SELECT * FROM themes WHERE themes.Handle = {[def]})


fun setDefaultTheme handle =
  exists <- hasRows (SELECT TRUE FROM themes
                     WHERE themes.Handle = {[handle]});
  if exists then
    KeyVal.set "defaultTheme" handle
  else
    error <xml>The theme {[handle]} doesn't exist in the database!</xml>


    (*
val defaultTheme =
  def <- KeyVal.unsafeGet "defaultTheme";
  t <- themeOfId def;
  case t of
  | None    => error <xml>Default theme not found!</xml>
  | Some t' => return t'
  *)


  (*
val currThemeId : transaction string =
  theme <- getCookie selectedTheme;
  case theme of
  | None   => KeyVal.unsafeGet "defaultTheme"
  | Some t => return t


val getTheme =
  theme <- Util.bindOptM themeOfId (getCookie selectedTheme);
  let val curTheme =
    case theme of
    | None   => clearCookie selectedTheme; defaultTheme
    | Some t => return t
  in
    { Filename = css, TabColor = color, ... } <- curTheme;
    return (File.linkCss css, color)
  end
  *)


val currentSessionTheme =
  selected <- getCookie selectedTheme;
  case selected of
  | None =>
    getDefaultTheme
  | Some t =>
    t <- oneOrNoRows1 (SELECT * FROM themes WHERE themes.Handle = {[t]});
    case t of
    | None =>
      clearCookie selectedTheme;
      getDefaultTheme
    | Some t =>
      return t
      *)


fun themeSwitcher themes' curr act : xbody =
  <xml><form>
    <select{#Theme}>
      {List.mapX (fn { Nam = name, ... } =>
        <xml><option value={name} selected={name = curr}>{[name]}</option></xml>)
        themes'}
    </select>
    <submit action={act} value="Switch theme"/>
  </form></xml>


fun setTheme t =
  time <- now;
  setCookie selectedTheme { Value = t, Secure = False
                          , Expires = Some (addSeconds time (86400 * 365)) }


open Tags

fun layout' theme color (title' : string) (class' : css_class) desc (body' : xbody) =
  <xml>
    <head>
      <meta charset="utf-8"/>
      <title>{[title']}</title>
      <meta name="description" content={desc}/>
      <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
      <meta name="theme-color" content={color}/>
      <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>
      <!-- <link rel="icon" type="image/png" href=""/> -->
      <link rel="stylesheet" type="text/css" href={theme}/>
    </head>
    <body class={class'}>{body'}</body>
  </xml>



fun layout (title' : string) class' desc body' =
  { Link = theme, TabColor = color, ... } <- currentSessionTheme;
  return (layout' theme color title' class' desc body')


fun layoutWithSwitcher act title' class' desc f =
  curr <- currentSessionTheme;
  themes <- allThemes;
  return <| layout' curr.Link curr.TabColor title' class' desc (f (themeSwitcher themes curr.Nam act))

  (*
  let
    val color =
      case List.find (fn { Filename = f, ... } => f = id) themes of
      | Some { TabColor = c, ... } => return c
      | None => clearCookie selectedTheme;
                error <xml>Invalid current theme: {[id]}</xml>

    val switcher = themeSwitcher themes id act
  in
    color <- color;
    return (layout' (File.linkCss id) color title' class' desc (f switcher))
  end
  *)


val navMenu =
  let
    mkMenu <xml>[ </xml>
  where
    fun mkMenu acc items = case items of
      | [] => <xml/>
      | item :: [] =>
        <xml>{acc}{item} ]</xml>
      | item :: rest =>
        mkMenu <xml>{acc}{item} / </xml> rest
  end
