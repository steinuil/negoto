table themes :
  { Nam      : string
  , Filename : string
  , TabColor : string }
  PRIMARY KEY Filename
  CONSTRAINT UniqueName UNIQUE Nam


type theme = { Nam : string, Filename : string, TabColor : string }


cookie selectedTheme : string


fun addTheme { Nam = name, TabColor = tabColor, Filename = fname } file =
  File.saveCss fname file;
  dml (INSERT INTO themes (Nam, Filename, TabColor)
       VALUES ({[name]}, {[fname]}, {[tabColor]}))


fun deleteTheme filename =
  def <- KeyVal.unsafeGet "defaultTheme";
  if filename <> def then
    File.deleteCss filename;
    dml (DELETE FROM themes WHERE Filename = {[filename]})
  else
    error <xml>You can't delete the default theme!</xml>


fun setDefaultTheme filename =
  exists <- hasRows (SELECT TRUE FROM themes
                     WHERE themes.Filename = {[filename]});
  if exists then
    KeyVal.set "defaultTheme" filename
  else
    error <xml>The theme "{[filename]}" doesn't exist in the database!</xml>


fun themeOfId name =
  oneOrNoRows1 (SELECT * FROM themes WHERE themes.Filename = {[name]})


val allThemes =
  queryL1 (SELECT * FROM themes)


val defaultTheme =
  def <- KeyVal.unsafeGet "defaultTheme";
  t <- themeOfId def;
  case t of
  | None    => error <xml>Default theme not found!</xml>
  | Some t' => return t'


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


fun themeSwitcher themes' curr act : xbody =
  <xml><form>
    <select{#Theme}>
      {List.mapX (fn { Filename = id, Nam = name, ... } =>
        <xml><option value={id} selected={id = curr}>{[name]}</option></xml>)
        themes'}
    </select>
    <submit action={act} value="Switch theme"/>
  </form></xml>


fun setTheme t =
  setCookie selectedTheme { Value = t, Expires = None, Secure = False }


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
      <!-- <meta name="msapplication-config" content="browserconfig.xml" /> -->
      <link rel="stylesheet" type="text/css" href={theme}/>
    </head>
    <body class={class'}>{body'}</body>
  </xml>



fun layout (title' : string) class' desc body' =
  (theme, color) <- getTheme;
  return (layout' theme color title' class' desc body')


fun layoutWithSwitcher act title' class' desc f =
  id <- currThemeId;
  themes <- allThemes;
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
