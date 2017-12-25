style post
style info
style description
style name
style subject
style post_body
style catalog_thread
style separator
style button
style hidden_field
style subject_field
style post_form
style container

style base_page
style front_page
style tag_page
style thread_page
style error_page


val sourceUrl = bless 'https://github.com/steinuil/negoto'


val errorPage =
  <xml>Error</xml>


val menu els : xbody = let
  fun toLink (url', title', name') =
    <xml><a href={url'} title={title'}>{[name']}</a></xml>

  val links =
    List.mp toLink els
    |> Util.interpose <xml> / </xml>
    |> List.mapX (fn x => x)
in
  <xml>[ {links} ]</xml>
end


val show_tag =
  mkShow (fn { Nam = name, Slug = slug } =>
    "/" ^ name ^ "/ - " ^ slug)


(* Create a subform that can hold up to `max` files. *)
(* FIXME: fails with `Fatal error: Tried to read a normal form input as files` when files in subforms *)
fun filesForm [form ::: {Type}] [[Files] ~ form] max
  : transaction (xml [Form, Dyn, Body] form [Files = list { File : file, Spoiler : bool }])
= let
  val newFile =
    spoil <- fresh;
    return <xml><div><entry>
      <upload{#File} />
      <checkbox{#Spoiler} class="hidden-field" id={spoil} />
      <label for={spoil} class="button">Spoiler</label>
    </entry></div></xml>

  fun files' ls = case ls of
    | [] => <xml/>
    | f :: rs => <xml>{f}{files' rs}</xml>
in
  f1 <- newFile;
  files <- source (f1 :: []);
  return <xml>
    <subforms{#Files}>
      <dyn signal={fs <- signal files; return (files' fs)} />
    </subforms>
    <div>
      <span onclick={fn _ =>
        f <- get files;
        if List.length f >= max then return () else
          newF <- newFile;
          set files (newF :: f)
      }>+</span>
      <span onclick={fn _ =>
        f <- get files; case f of
        | f' :: [] => return ()
        | ls :: rs => set files rs
        | [] => return ()
      }>-</span>
    </div>
  </xml>
end


fun layout (title' : string) (class' : css_class) body' = return <xml>
  <head>
    <title>{[title']}</title>
    <link type="text/css" rel="stylesheet" href="/style.css" />
  </head>
  <body class={class'}>{body'}</body>
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


and readme () =
  tags <- Data.allTags;
  layout "Readme" base_page <xml>
    <header>
      {navigation tags}
      <h1>Readme</h1>
    </header>
    <main>
      README HERE
    </main>
  </xml>


and tag name =
  tags <- Data.allTags;
  case List.find (fn t => t.Nam = name) tags of
  | None => error errorPage
  | Some tag' =>
    threads <- (Data.catalogByTag tag'.Nam `bind` List.mapXM catalogThread);
    postForm <- catalogForm tag'.Nam;
    layout (show tag') tag_page <xml>
      <header>
        {navigation tags}
        <h1>{[tag']}</h1>
      </header>
      <main>
        {postForm}
        <div class="container">{threads}</div>
      </main>
    </xml>


and thread id =
  thread' <- Data.threadById id;
  case thread' of
  | None => error errorPage
  | Some (t, posts) =>
    tags <- Data.allTags;
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
          {case thread'.Files of
          | [] => <xml>link</xml>
          | file :: _ => <xml>{[file.Hash]}</xml>}
        </a>
      </figure>
      <div class="info">
        <time>{updated}</time>
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
      {[file.Nam]}
    </figure></xml>}
    <div class="info">
      <span class="name">{[post'.Nam]}</span>
      <time>{[post'.Time]}</time> &#8470;{[post'.Id]}
    </div>
    <div class="post-body">{[post'.Body]}</div>
  </div>
</xml>


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


and catalogForm (boardId : string) : transaction xbody =
  submitButton <- fresh;
  spoilerButton <- fresh;
  return <xml><form class="post-form">
    <div>
      <textbox{#Subject} class="subject-field" required placeholder="Subject" />
    </div>
    <div>
      <textbox{#Nam} required placeholder="Name" value="Anonymous" />
      <label for={submitButton} class="button">Post</label>
    </div>
    <textarea{#Body} placeholder="Comment" />
    <div>
      <upload{#File} />
      <checkbox{#Spoiler} class="hidden-field" id={spoilerButton} />
      <label for={spoilerButton} class="button">Spoiler</label>
    </div>
    <subforms{#Tags}>
      <entry><hidden{#Id} value={show boardId} /></entry>
    </subforms>
    <submit action={catalogFormHandler} class="hidden-field" id={submitButton} />
  </form></xml>


and catalogFormHandler f = let
  val files =
    if blobSize (fileData f.File) > 0 then
      let val _ = naughtyDebug "ayy lmao" in
      { File = f.File, Spoiler = f.Spoiler } :: []
      end
    else []

  val thread = f -- #Tags -- #File -- #Spoiler ++
    { Tags = List.mp (fn x => x.Id) f.Tags, Files = files }
in
  res <- Data.newThread thread;
  layout "Inspect post" base_page <xml>
    <main>
      {[f.Body]}
    </main>
  </xml>
end


and threadForm (threadId : int) : transaction xbody =
  submitButton <- fresh;
  bumpButton <- fresh;
  spoilerButton <- fresh;
  return <xml><form class="post-form">
    <div>
      <textbox{#Nam} required placeholder="Name" value="Anonymous" />

      <checkbox{#Bump} class="hidden-field" checked id={bumpButton} />
      <label for={bumpButton} class="button">Bump</label>
      <label for={submitButton} class="button">Post</label>
    </div>
    <textarea{#Body} placeholder="Comment" />
    <div>
      <upload{#File} />
      <checkbox{#Spoiler} class="hidden-field" id={spoilerButton} />
      <label for={spoilerButton} class="button">Spoiler</label>
    </div>
    <hidden{#Thread} value={show threadId} />
    <submit action={threadFormHandler} class="hidden-field" id={submitButton} />
  </form></xml>


and threadFormHandler f = let
  val files =
    if blobSize (fileData f.File) > 0 then
      { File = f.File, Spoiler = f.Spoiler } :: []
    else
      []

  val post = f -- #Thread -- #File -- #Spoiler ++
    { Thread = readError f.Thread, Files = files }
in
  Data.newPost post;
  layout "Inspect post" base_page <xml>
    <main>
      {[f.Body]}
    </main>
  </xml>
end


(* FIXME: Can't use these until the fatal error in filesForm is fixed.
and threadForm (threadId : int) : transaction xbody =
  submitButton <- fresh;
  bumpButton <- fresh;
  files <- filesForm 4;
  return <xml><form class="post-form">
    <div>
      <textbox{#Nam} required placeholder="Name" value="Anonymous" />

      <checkbox{#Bump} class="hidden-field" checked id={bumpButton} />
      <label for={bumpButton} class="button">Bump</label>
      <label for={submitButton} class="button">Post</label>
    </div>
    <textarea{#Body} placeholder="Comment" />
    {files}
    <hidden{#Thread} value={show threadId} />
    <submit action={formHandler} class="hidden-field" id={submitButton} />
  </form></xml>


and formHandler f = let
  val files =
    List.filter (fn { File = f, ... } => blobSize (fileData f) > 0) f.Files

  val post = f -- #Thread -- #Files ++
    { Thread = readError f.Thread, Files = files }
in
  Data.newPost post;
  layout "Inspect post" base_page <xml>
    <main>
      {[f.Body]}
    </main>
  </xml>
end
*)


val main = redirect (url (front ()))
