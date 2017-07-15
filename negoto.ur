style post
style post_info
style post_body
style post_name


val sourceUrl = bless "https://github.com/steinuil/negoto"


val errorPage =
  <xml>Error</xml>


fun readme () =
  tags <- Data.allTags;
  return (layout "Readme" tags
    <xml>Read this.</xml>)


and threadPost post' = <xml>
  <div class="post">
    <div class="post-info">
      <span class="post-name">{[post'.Nam]}</span> {[post'.Time]} &#8470;{[post'.Id]}
    </div>
    <hr/>
    <div class="post-body">{[post'.Body]}</div>
  </div>
</xml>


and thread (id : int) =
  thread' <- Data.threadById id;
  case thread' of
  | None => error errorPage
  | Some t =>
    posts' <- Data.postsByThread t.Id;
    tags <- Data.allTags;
    return (layout ("Thread" ^ show id) tags <xml>
        <div>{case t.Tags of
          t :: _ => <xml>[ <a href={url (tag t)}>back</a> ]</xml>
        | [] => <xml/>}
          {[t.Subject]}
        </div>
        {List.mapX threadPost posts'}
      </xml>)


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
    return (layout ("/" ^ t.Nam ^ "/ - " ^ t.Slug) tags
      <xml>{List.mapX catalogThread threads}</xml>)


and front () =
  tags <- Data.allTags;
  return (baseLayout
    { Title = "Time-Telling Fortress"
    , Header = <xml>
      <div>Good Day, Brother.</div>
      <div>Welcome To The</div>
      <div>Time-Telling Fortress.</div>
    </xml>
    , Body = <xml>
      <ul>
        {List.mapX (fn t => <xml><li>
          <a href={url (tag t.Nam)}>/{[t.Nam]}/ - {[t.Slug]}</a>
        </li></xml>) tags}
      </ul>
    </xml>
    , Footer = <xml>
      Powered by <a href={sourceUrl}>Negoto</a>
    </xml> })


and baseLayout { Title = title', Header = header'
               , Body = body', Footer = footer' } =
  <xml>
    <head>
      <title>{[title']}</title>
      <link type="text/css" rel="stylesheet" href="/style.css" />
    </head>
    <body>
      <header>
        {header'}
      </header>
      <main>
        {body'}
      </main>
      <footer>
        {footer'}
      </footer>
    </body>
  </xml>


and layout (title' : string) tags' (body' : xbody) = let
  fun link' { Nam = name, Slug = slug } =
    <xml> / <a href={url (tag name)} title={slug}>{[name]}</a></xml>
in
  baseLayout
    { Title = title'
    , Header = <xml><nav>
      [ <a href={url (front ())} title="Home">Home</a> {List.mapX link' tags'} ]
      [ <a href={url (readme ())}>readme</a> / <a href={sourceUrl}>source</a> ]
    </nav></xml>
    , Body = body'
    , Footer = <xml>
      [ ayy ]
    </xml> }
end


val main = redirect (url (front ()))
