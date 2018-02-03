open Tags
open Styles

style base_page
style front_page
style catalog_page
style thread_page
style error_page


val errorPage =
  <xml>Error</xml>


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
        | _ :: [] => return ()
        | _ :: rs => set files rs
        | [] => return ()
      }>-</span>
    </div>
  </xml>
end


fun layout tags (title' : string) (class' : css_class) (body' : xbody) =
  siteName <- Admin.siteName;
  nav' <- navigation tags;
  Layout.layoutWithSwitcher switch_theme (title' ^ " - " ^ siteName) class' ""
    (fn switcher => <xml>
      <header>
        <nav>{nav'}</nav>
        <h1>{[title']}</h1>
      </header>
      <main>{body'}</main>
      <footer>{switcher}</footer>
    </xml>)


and switch_theme { Theme = t } =
  Layout.setTheme t;
  redirect (url (front ()))


and newsItem item : xbody =
  <xml><article class="news-item">
    <header><strong>{[item.Title]}</strong> by {[item.Author]} at {[item.Time]}</header>
    <div class="news_body">{Post.toHtml' item.Body}</div>
  </article></xml>


and front () =
  tags <- Data.allTags;
  news <- Admin.news;
  readme <- Admin.readme;
  readme <- Post.toHtml'' readme;
  siteName <- Admin.siteName;
  Layout.layout ("Front Page - " ^ siteName) front_page "" <xml>
    <header>
      <h1>{[siteName]}</h1>
    </header>
    <main>
      <div class="container">
        <section>
          <header>Boards</header>
          <ul class="section-body">
            {List.mapX (fn t => <xml><li>
              <a link={catalog t.Nam}>{[t]}</a>
            </li></xml>) tags}
          </ul>
        </section>
        <section>
          <header>News</header>
          <div class="section-body">{List.mapX newsItem news}</div>
        </section>
        <section>
          <header>Readme</header>
          <div class="section-body">{readme}</div>
        </section>
      </div>
    </main>
    <footer>Powered by <a href="https://github.com/steinuil/negoto">Negoto</a></footer>
  </xml>


and catalog name =
  tags <- Data.allTags;
  case List.find (fn t => t.Nam = name) tags of
  | None => error errorPage
  | Some tag =>
    threads <- (Data.catalogByTag tag.Nam `bind` List.mapXM catalogThread);
    postForm <- catalogForm tag.Nam;
    layout tags (show tag) catalog_page <xml>
      {postForm}
      <div class="container">{threads}</div>
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
      val title' =
        List.find (fn tag => tag.Nam = t.Tag) tags
        |> Option.mp show
        |> Option.get ""

      fun addTxt str =
        t <- get postBody;
        set postBody (t ^ str)
    in
      posts <- List.mapXM (threadPost addTxt) posts;
      pForm <- postForm postBody id;
      layout tags title' thread_page <xml>
        <header>[ <a link={catalog t.Tag}>back</a> ] {[t.Subject]}</header>
        <div class="container">{posts}</div>
        {if t.Locked then <xml/> else
        <xml>{tForm}{pForm}</xml>}
      </xml>
    end


and catalogThread thread' =
  updated <- Util.elapsed thread'.Updated;
  return <xml>
    <div class="catalog-thread">
      <figure>
        <a link={thread thread'.Id}>
          {case thread'.Files of
          | [] => <xml>link</xml>
          | file :: _ => <xml><figure>
            <img src={File.linkThumb file.Hash}/>
          </figure></xml>}
        </a>
      </figure>
      <div class="info">
        <time>{updated}</time>
        <span class="separator">/</span>
        {[thread'.Count]} post{if thread'.Count > 1 then <xml>s</xml> else <xml/>}
        {if thread'.Locked then <xml><span class="separator">/</span> Locked</xml> else <xml/>}
      </div>
      <div class="description">
        <span class="subject">{[thread'.Subject]}</span>
        <span class="separator">//</span>
        <span class="post-body">{[thread'.Body]}</span>
      </div>
    </div>
  </xml>


and threadPost addToPostBody post' =
  expanded <- source False;
  currUrl <- currentUrl;
  let
    fun imgSrc file exp =
      if exp then
        File.linkImage file.Hash file.Mime
      else
        File.linkThumb file.Hash

    val picture = case post'.Files of
      | [] => <xml/>
      | file :: _ => <xml><figure onclick={fn _ => exp <- get expanded; set expanded (not exp)}>
        <noscript><img src={File.linkThumb file.Hash}/></noscript>
        <dyn signal={exp <- signal expanded; return <xml><img src={imgSrc file exp}/></xml>}/>
      </figure></xml>
  in
    return <xml>
      <div class="post" id={Post.id post'.Id}>
        {picture}
        <div class="info">
          <span class="name">{[post'.Nam]}</span>
          <time>{[post'.Time]}</time>
          <a class="clickable" href={Post.link (Post.id post'.Id)}>&#8470;</a><span class="clickable"
            onclick={fn _ => addToPostBody (">>" ^ show post'.Id ^ "\n")}>{[post'.Id]}</span>
        </div>
        <div class="post-body">{Post.toHtml currUrl post'.Body}</div>
      </div>
    </xml>
  end


and navigation tags =
  affiliateLinks <- Admin.links;
  let
    val boards =
      <xml><a link={front ()}>Home</a></xml>
      :: List.mp (fn { Nam = name, Slug = slug } =>
        <xml><a link={catalog name} title={slug}>{[name]}</a></xml>)
        tags

    val aff =
      List.mp (fn { Link = link, Nam = name } =>
        <xml><a href={link}>{[name]}</a></xml>)
        affiliateLinks
  in
    return <xml>{Layout.navMenu boards} {Layout.navMenu aff}</xml>
  end


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
    <hidden{#Tag} value={show boardId}/>
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

  val thread' = f -- #File -- #Spoiler ++
    { Files = files }
in
  id <- Data.newThread thread';
  redirect (url (thread id))
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
