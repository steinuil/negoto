datatype themes = Yotsuba | YotsubaB


cookie theme : themes


val getTheme =
  theme' <- getCookie theme;
  case theme' of
  | Some Yotsuba =>
    return (bless "/yotsuba.css", "#FFD6AE")
  | Some YotsubaB =>
    return (bless "/yotsuba-b.css", "#D0D5E7")
  | _ =>
    return (bless "/yotsuba.css", "#FFD6AE")


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
