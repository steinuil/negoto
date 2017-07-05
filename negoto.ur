fun notFound () =
  return <xml>
    <body>
      <h1>404</h1>
    </body>
  </xml>

fun tagPage (name : string) : transaction page =
  tag <- Data.tagByName name;
  case tag of
  | None => redirect (url (notFound ()))
  | Some t =>
    return <xml>
      <body>
        <h1>{[t.Nam]}</h1>
      </body>
    </xml>

fun main () =
  tags <- Data.allTags ();
  return <xml>
    <head>
      <title>negoto</title>
    </head>
    <body>
      <h1>Negoto</h1>

      Tag list
      <ul>
        {List.mapX (fn x => <xml>
          <li><a href={url (tagPage x.Nam)}>{[x.Nam]} - {[x.Slug]}</a></li>
        </xml>) tags}
      </ul>
    </body>
  </xml>
