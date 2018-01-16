style post
style info
style description
style name
style subject
style post_body
style catalog_thread
style separator
style clickable
style button
style hidden_field
style subject_field
style post_form
style container
style section_body
style news_item
style news_body

style base_page
style front_page
style catalog_page
style thread_page
style error_page
style readme_page


val sourceUrl = bless 'https://github.com/steinuil/negoto'


val errorPage =
  <xml>Error</xml>


val affiliateLinks =
  (sourceUrl, "Source", "source")
  :: []


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


fun layout (title' : string) (class' : css_class) body' =
  Layout.layout title' class' "" body'


and newsItem item : xbody =
  <xml><article class="news-item">
    <header><strong>{[item.Title]}</strong> by {[item.Author]} at {[item.Time]}</header>
    <div class="news_body">{Post.toHtml' item.Body}</div>
  </article></xml>


and front () =
  tags <- Data.allTags;
  news <- Admin.news;
  readme <- Admin.readme;
  layout "Front Page - Negoto" front_page <xml>
    <header>
      <h1>Negoto</h1>
    </header>
    <main>
      <div class="container">
        <section>
          <header>Boards</header>
          <ul class="section-body">
            {List.mapX (fn t => <xml><li>
              <a href={url (catalog t.Nam)}>{[t]}</a>
            </li></xml>) tags}
          </ul>
        </section>
        <section>
          <header>News</header>
          <div class="section-body">{List.mapX newsItem news}</div>
        </section>
        <section>
          <header>Readme</header>
          <div class="section-body">{Post.toHtml' readme.Body}</div>
          <footer>last updated at {[readme.Updated]}</footer>
        </section>
      </div>
    </main>
    <footer>Powered by <a href={sourceUrl}>Negoto</a></footer>
  </xml>


and catalog name =
  tags <- Data.allTags;
  case List.find (fn t => t.Nam = name) tags of
  | None => error errorPage
  | Some tag' =>
    threads <- (Data.catalogByTag tag'.Nam `bind` List.mapXM catalogThread);
    postForm <- catalogForm tag'.Nam;
    layout (show tag') catalog_page <xml>
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
    tForm <- threadForm t.Id;
    postBody <- source "";
    let
      val title' = case t.Tags of
        | [] => ""
        | tg' :: _ => (case List.find (fn t => t.Nam = tg') tags of
          | None => ""
          | Some tag' => show tag')

      val back = case t.Tags of
        | [] => <xml/>
        | t :: _ => <xml>[ <a href={url (catalog t)}>back</a> ]</xml>

      fun addTxt str =
        t <- get postBody;
        set postBody (t ^ str)
    in
      posts <- List.mapXM (threadPost addTxt) posts;
      pForm <- postForm postBody id;
      layout title' thread_page <xml>
        <header>
          {navigation tags}
          <h1>{[title']}</h1>
        </header>
        <main>
          <header>{back} {[t.Subject]}</header>
          <div class="container">{posts}</div>
          {tForm}
          {pForm}
        </main>
        <footer>
          ayy lmao
        </footer>
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
        {[thread'.Count]} post{if thread'.Count > 1 then <xml>s</xml> else <xml/>}
      </div>
      <div class="description">
        <span class="subject">{[thread'.Subject]}</span>
        <span class="separator">//</span>
        <span class="post-body">{[thread'.Body]}</span>
      </div>
    </div>
  </xml>


and threadPost addToPostBody post' =
  currUrl <- currentUrl;
  return <xml>
    <div class="post" id={Post.id post'.Id}>
      {case post'.Files of
      | [] => <xml/>
      | file :: _ => <xml><figure>
        {[file.Nam]}
      </figure></xml>}
      <div class="info">
        <span class="name">{[post'.Nam]}</span>
        <time>{[post'.Time]}</time>
        <a class="clickable" href={Post.link (Post.id post'.Id)}>&#8470;</a><span class="clickable"
          onclick={fn _ => addToPostBody (">>" ^ show post'.Id ^ "\n")}>{[post'.Id]}</span>
      </div>
      <div class="post-body">{Post.toHtml currUrl post'.Body}</div>
    </div>
  </xml>


and tagLinks tags =
  menu <| (url (front ()), "Home", "Home")
       :: List.mp (fn { Nam = name, Slug = slug } =>
         (url (catalog name), slug, name)) tags


and otherLinks () =
  menu affiliateLinks


and navigation tags =
  <xml><nav>{tagLinks tags} {otherLinks ()}</nav></xml>


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
    <submit action={create_thread} class="hidden-field" id={submitButton} />
  </form></xml>


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
    <submit action={create_post} class="hidden-field" id={submitButton} />
  </form></xml>


and create_thread f = let
  val files =
    if blobSize (fileData f.File) > 0 then
      { File = f.File, Spoiler = f.Spoiler } :: []
    else []

  val thread' = f -- #Tags -- #File -- #Spoiler ++
    { Tags = List.mp (fn x => x.Id) f.Tags, Files = files }
in
  if Post.isValid f.Body then
    id <- Data.newThread thread';
    redirect (url (thread id))
  else
    error errorPage
end


and create_post f = let
  val files =
    if blobSize (fileData f.File) > 0 then
      { File = f.File, Spoiler = f.Spoiler } :: []
    else
      []

  val post = f -- #Thread -- #File -- #Spoiler ++
    { Thread = readError f.Thread, Files = files }
in
  if Post.isValid f.Body then
    _ <- Data.newPost post;
    redirect (url (thread post.Thread))
  else
    error errorPage
end


and create_post' f =
  let val post = f -- #Spoiler ++ { Files = [] } in
    _ <- Data.newPost post;
    return ()
  end


and postForm (body : source string) (threadId : int) : transaction xbody =
  name <- source "Anonymous";
  bump <- source True;
  spoiler <- source False;
  bumpId <- fresh;
  spoilerId <- fresh;
  let
    val mkPost =
      n <- get name; b <- get bump; bd <- get body; s <- get spoiler;
      rpc <| create_post' { Nam = n, Bump = b, Body = bd
                          , Thread = threadId, Spoiler = s }
  in
    return <xml><div class="post-form">
      <div>
        <ctextbox source={name} placeholder="Name"/>
        <ccheckbox source={bump} id={bumpId} class="hidden-field"/>
        <label for={bumpId} class="button">Bump</label>
        <span class="button" onclick={fn _ => mkPost}>Post</span>
      </div>
      <ctextarea source={body}/>
      <div>
        <ccheckbox source={spoiler} id={spoilerId} class="hidden-field"/>
        <label for={spoilerId} class="button">Spoiler</label>
      </div>
    </div></xml>
  end