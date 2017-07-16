style post
style info
style description
style name
style subject
style post_body
style catalog_thread
style separator

style tag_page
style thread_page
style front_page
style base_page


val sourceUrl = bless "https://github.com/steinuil/negoto"


val errorPage =
  <xml>Error</xml>


type formm =
  { Subject : string
  , Nam : string
  , Body : string
  , File : file
  , Sage : bool
  , Spoiler : bool }


fun readme () =
  tags <- Data.allTags;
  return (layout base_page "Readme" tags
    <xml>Read this.</xml>)


and formHandler (f : formm) =
  return <xml><body>
    {[f.Subject]}
  </body></xml>


and postForm () =
  <xml><form>
    <textbox{#Subject} placeholder="Subject" />
    <textbox{#Nam} placeholder="Name" />
    <br/>
    <textarea{#Body} placeholder="Comment" />
    <br/>
    <upload{#File} />
    <checkbox{#Sage} />
    <checkbox{#Spoiler} />
    <submit action={formHandler} value="Post" />
  </form></xml>


and threadPost post' = <xml>
  <div class="post">
    {case post'.Files of
    | [] => <xml/>
    | file :: _ => <xml><figure>
      &lt;image here&gt;
    </figure></xml>}
    <div class="info">
      <span class="name">{[post'.Nam]}</span>
      <time>{[post'.Time]}</time> &#8470;{[post'.Id]}
    </div>
    <div class="post-body">{[post'.Body]}</div>
  </div>
</xml>


and catalogThread thread' =
  updated <- Util.elapsed thread'.Updated;
  return <xml>
    <div class="catalog-thread">
      <figure>
        <a href={url (thread thread'.Id)}>
          {case Util.head thread'.Files of
          | None => <xml/>
          | Some file => <xml>&lt;image here&gt;</xml>}
        </a>
      </figure>
      <div class="info">
        <time>{[updated]}</time>
        <span class="separator">/</span>
        &lt;count here&gt;
      </div>
      <div class="description">
        <span class="subject">{[thread'.Subject]}</span>
        <span class="separator">//</span>
        <span class="post-body">{[thread'.Body]}</span>
      </div>
    </div>
  </xml>


and thread (id : int) =
  thread' <- Data.threadById id;
  case thread' of
  | None => error errorPage
  | Some t =>
    posts' <- Data.postsByThread t.Id;
    tags <- Data.allTags;
    return (layout thread_page ("Thread" ^ show id) tags <xml>
        {postForm ()}
        <div>{case t.Tags of
          t :: _ => <xml>[ <a href={url (tag t)}>back</a> ]</xml>
        | [] => <xml/>}
          {[t.Subject]}
        </div>
        {List.mapX threadPost posts'}
      </xml>)


and tag (name : string) =
  tags <- Data.allTags;
  case List.find (fn x => x.Nam = name) tags of
  | None => error errorPage
  | Some t =>
    threads <- Data.catalogByTag t.Nam;
    threads <- List.mapXM catalogThread threads;
    return (layout tag_page ("/" ^ t.Nam ^ "/ - " ^ t.Slug) tags
      <xml>{threads}</xml>)


and front () =
  tags <- Data.allTags;
  return (baseLayout front_page
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


and baseLayout typ
  { Title = title', Header = header'
  , Body = body', Footer = footer' } =
  <xml>
    <head>
      <title>{[title']}</title>
      <link type="text/css" rel="stylesheet" href="/style.css" />
    </head>
    <body class={typ}>
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


and layout typ (title' : string) tags' (body' : xbody) = let
  fun link' { Nam = name, Slug = slug } =
    <xml> / <a href={url (tag name)} title={slug}>{[name]}</a></xml>
in
  baseLayout typ
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
