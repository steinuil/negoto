val errorPage (err : string) =
  <xml>{[err]}</xml>

fun tagPage (name : string) : transaction page =
  tag <- Data.tagByName name;
  case tag of
  | None => error (errorPage "404")
  | Some t =>
    threads <- Data.threadsByTag t.Nam;
    return <xml>
      <body>
        <h1>{[t.Nam]}</h1>
        <main>
          {List.mapX (fn x => <xml>
            <div>[{[x.Id]}] {[x.Subject]} [{[x.Updated]}]</div>
          </xml>) threads}
        </main>
      </body>
    </xml>

fun tagList ls =
  Util.joinStrings " " <| List.mp (fn x => "[" ^ x ^ "]") ls

val catalog =
  threads <- Data.catalog;
  return <xml>
    <body>
      {List.mapX (fn thread' => let
        val tags' = tagList thread'.Tags
        val locked' = if thread'.Locked then " [LOCKED] " else ""
      in <xml>
        <div>
          <div>{[thread'.Id]}. {[thread'.Subject]} {[tags']} {[locked']}</div>
          <div>{[thread'.Nam]} {[thread'.Time]}</div>
          <div>{[thread'.Body]}</div>
        </div>
      </xml> end) threads}
    </body>
  </xml>

val main =
  tags <- Data.allTags;
  return <xml>
    <head>
      <title>negoto</title>
    </head>
    <body>
      <h1>Negoto</h1>

      <a href={url catalog}>All threads</a>

      Tag list
      <ul>
        {List.mapX (fn x => <xml>
          <li><a href={url (tagPage x.Nam)}>{[x.Nam]} - {[x.Slug]}</a></li>
        </xml>) tags}
      </ul>
    </body>
  </xml>
