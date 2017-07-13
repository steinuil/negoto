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

and threadPost post' = <xml>
  <div>
    <div>{[post'.Nam]} {[post'.Time]} &#8470;{[post'.Id]}</div>
    <hr/>
    <div>{[post'.Body]}</div>
  </div>
</xml>

and thread (id : int) =
  posts <- Data.postsByThread id;
  case posts of
  | [] => error errorPage
  | _ =>
    return <xml>
      <body>
        <main>
          {List.mapX threadPost posts}
        </main>
      </body>
    </xml>

and catalogThread thread' = <xml>
  <div>
    <figure>
      <a href={url (thread thread'.Id)}>
        {case Util.head thread'.Files of
        | None => <xml/>
        | Some file => <xml>
          [image {[file.Nam]}]
        </xml>}
      </a>
    </figure>
    <div>{[thread'.Updated]} / [count here]</div>
    <div>{[thread'.Subject]} // {[thread'.Body]}</div>
  </div>
</xml>

and tag (name : string) =
  tags <- Data.allTags;
  case List.find (fn x => x.Nam = name) tags of
  | None => error errorPage
  | Some t =>
    threads <- Data.catalogByTag t.Nam;
    return <xml>
      <body>
        <header>
          {navigator tags}
          <h1>/{[t.Nam]}/ - {[t.Slug]}</h1>
        </header>
        <main>
          {List.mapX catalogThread threads}
        </main>
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
        <div>Welcome To The</div>
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
