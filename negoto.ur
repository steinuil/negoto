val sourceUrl = bless "https://github.com/steinuil/negoto"

val errorPage =
  <xml>Error</xml>

fun navigator tags = let
  fun link' t =
    <xml> / <a href={url (tag t.Nam)} title={t.Slug}>{[t.Nam]}</a></xml>
in
  <xml><nav>
    [ <a href={url (front ())} title="Home">Home</a> {List.mapX link' tags} ]
    [ <a href={url (readme ())}>readme</a> / <a href={sourceUrl}>source</a> ]
  </nav></xml>
end

and readme () =
  return <xml>
    <body>
      Read this.
    </body>
  </xml>

and tag (name : string) =
  tags <- Data.allTags;
  case List.find (fn x => x.Nam = name) tags of
  | None => error errorPage
  | Some t => return <xml>
    <body>
      <header>
        {navigator tags}
        <h1>/{[t.Nam]}/ - {[t.Slug]}</h1>
      </header>
    </body>
  </xml>

and front () =
  tags <- Data.allTags;
  return <xml>
    <head>
      <title>Time-Telling Fortress</title>
    </head>
    <body>
      <header>
        <div>Good Day, Brother.</div>
        <div>Time-Telling Fortress.</div>
      </header>
      <ul>
        {List.mapX (fn t => <xml><li>
          <a href={url (tag t.Nam)}>/{[t.Nam]}/ - {[t.Slug]}</a>
        </li></xml>) tags}
      </ul>
      <footer>
        Powered by <a href={sourceUrl}>Negoto</a>
      </footer>
    </body>
  </xml>

val main = redirect (url (front ()))

(*
  tags <- Data.allTags;
  return <xml>
    <head>
      <title>Time-Telling Fortress</title>
    </head>
    <body>
      <header>
        <div>Good Day, Brother.</div>
        <div>Time-Telling Fortress.</div>
      </header>
      <ul>
        {List.mapX (fn t => <xml><li>
          <a href={url (tag t.Nam)}>/{[t.Nam]}/ - {[t.Slug]}</a>
        </li></xml>) tags}
      </ul>
      <footer>
        Powered by <a href="https://github.com/steinuil/negoto">Negoto</a>
      </footer>
    </body>
  </xml>
  *)



(*
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

fun catalogThread thread = let
  val tags' = tagList thread.Tags
  val locked' = if thread.Locked then " [LOCKED]" else ""
in
  <xml><div>
    <div>{[thread.Id]}. {[thread.Subject]} {[tags']}{[locked']}</div>
    <div>{[thread.Nam]} {[thread.Time]}</div>
    <div>{[thread.Body]}</div>
  </div></xml>
end

val catalog =
  threads <- Data.catalog;
  return <xml>
    <body>
      {List.mapX catalogThread threads}
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
*)
