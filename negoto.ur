style post
style info
style description
style name
style subject
style post_body
style catalog_thread
style separator
style button
style hidden_form
style post_form

style tag_page
style thread_page
style front_page
style base_page


val sourceUrl = bless "https://github.com/steinuil/negoto"


val errorPage =
  <xml>Error</xml>


val menu : list (url * string * string) -> xbody =
  List.mp (fn (url', title', name') =>
    <xml><a href={url'} title={title'}>{[name']}</a></xml>)
  >>> Util.interpose <xml> / </xml>
  >>> fn els => <xml>[ {List.mapX (fn x => x) els} ]</xml>


val show_tag =
  mkShow (fn { Nam = name, Slug = slug } =>
    "/" ^ name ^ "/ - " ^ slug)


fun layout (title' : string) typ body' = return <xml>
  <head>
    <title>{[title']}</title>
    <link type="text/css" rel="stylesheet" href="/style.css" />
  </head>
  <body class={typ}>{body'}</body>
</xml>


and front () =
  tags <- Data.allTags;
  layout "Time-Telling Fortress" front_page <xml>
    <header>
      <div>Good Day, Brother.</div>
      <div>Welcome To The</div>
      <div>Time-Telling Fortress.</div>
    </header>
    <main>
      <ul>
        {List.mapX (fn t => <xml><li>
          <a href={url (tag t.Nam)}>{[t]}</a>
        </li></xml>) tags}
      </ul>
    </main>
    <footer>
      Powered by <a href={sourceUrl}>Negoto</a>
    </footer>
  </xml>



and formHandler f =
  return <xml><body>
    {[f.Body]}
  </body></xml>


and threadForm id =
  submitButton <- fresh;
  fileButton <- fresh;
  sageButton <- fresh;
  spoilerButton <- fresh;
  return <xml><form class="post-form">
    <textbox{#Nam} placeholder="Name" />
    <label for={submitButton} class="button">Post</label>
    <br/>
    <textarea{#Body} placeholder="Comment" />
    <br/>
    <label for={fileButton} class="button">Add file</label>

    <checkbox{#Spoiler} class="hidden-form" id={spoilerButton} />
    <label for={spoilerButton} class="button">Spoiler</label>

    <checkbox{#Sage} class="hidden-form" id={sageButton} />
    <label for={sageButton} class="button">Sage</label>
    <upload{#File} class="hidden-form" id={fileButton} />
    <hidden{#Thread} value={show id} />
    <submit action={formHandler} class="hidden-form" id={submitButton} />
  </form></xml>


and tagLinks tags =
  menu <| (url (front ()), "Home", "Home")
       :: List.mp (fn { Nam = name, Slug = slug } =>
         (url (tag name), slug, name)) tags


and otherLinks () =
  menu <| (url (readme ()), "Readme", "readme")
       :: (sourceUrl,       "Source", "source")
       :: []


and navigation tags =
  <xml>{tagLinks tags} {otherLinks ()}</xml>


and readme () =
  tags <- Data.allTags;
  layout "Readme" base_page <xml>
    <header>
      {navigation tags}
      <h1>Readme</h1>
    </header>
    <main>Read this.</main>
  </xml>


and tag name =
  tags <- Data.allTags;
  case List.find (fn t => t.Nam = name) tags of
  | None => error errorPage
  | Some tag' =>
    threads <- Data.catalogByTag tag'.Nam;
    threads <- List.mapXM catalogThread threads;
    layout (show tag') tag_page <xml>
      <header>
        {navigation tags}
        <h1>{[tag']}</h1>
      </header>
      <main>
        {threads}
      </main>
    </xml>


and thread id =
  thread' <- Data.threadById id;
  case thread' of
  | None => error errorPage
  | Some t =>
    tags <- Data.allTags;
    posts <- Data.postsByThread t.Id;
    posts <- List.mapXM threadPost posts;
    tForm <- threadForm t.Id;
    let
      val title' = case t.Tags of
        | [] => ""
        | tg' :: _ => (case List.find (fn t => t.Nam = tg') tags of
          | None => ""
          | Some tag' => show tag')

      val back = case t.Tags of
        | [] => <xml/>
        | t :: _ => <xml>[ <a href={url (tag t)}>back</a> ]</xml>
    in
      layout title' thread_page <xml>
        <header>
          {navigation tags}
          <h1>{[title']}</h1>
        </header>
        <main>
          {back} {[t.Subject]}
          {posts}
          {tForm}
        </main>
      </xml>
    end


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


and threadPost post' = return <xml>
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



val main = redirect (url (front ()))
