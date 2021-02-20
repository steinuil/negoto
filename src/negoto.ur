open Tags
open Styles
structure E = Error

style base_page
style front_page
style catalog_page
style thread_page


val show_board : show Data.board =
  mkShow (fn { Id = id, Nam = name } =>
    "/" ^ id ^ "/ - " ^ name)


fun srcOf (file : Data.postFile) = case file of
  | { Spoiler = True, ... } =>
    File.spoiler
  | { Src = src, ... } =>
    src


fun thumbOf (file : Data.postFile) = case file of
  | { Spoiler = True, ... } =>
    File.spoiler
  | { Thumb = t, ... } =>
    t


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


fun layout boards (title' : string) (class' : css_class) (body : xbody) =
  siteName <- Admin.siteName;
  nav' <- navigation boards;
  banner' <- Layout.randBanner;
  Layout.layoutWithSwitcher switch_theme (title' ^ " - " ^ siteName) class' ""
    (fn switcher => <xml>
      <header>
        <nav>{nav'}</nav>
        {case banner' of
        | None => <xml/>
        | Some b =>
          <xml><img class="banner" width={300} height={100} src={b}/></xml>}
        <h1>{[title']}</h1>
      </header>
      <main>{body}</main>
      <footer>{switcher}</footer>
    </xml>)


and switch_theme { Theme = t } =
  Layout.setTheme (readError t);
  redirect (url (front ()))


and newsItem item : transaction xbody =
  body' <- Post.toHtml item.Body;
  return <xml><article class="news-item">
    <header><strong>{[item.Title]}</strong> by {[item.Author]} at {[item.Time]}</header>
    <div class="news_body">{body'}</div>
  </article></xml>


and front () =
  boards <- Data.allBoards;
  news <- Admin.news;
  news <- List.mapXM newsItem news;
  readme <- Admin.readme;
  readme <- Post.toHtml readme;
  siteName <- Admin.siteName;
  recentPosts <- Data.recentPosts 5;
  recentPosts <- List.mapXM
    (fn p =>
      elapsed <- Util.elapsed p.Time;
      return <xml>
        <li class="recent_post">
          <a link={thread p.Thread}>
            >>/{[p.Board]}/{[p.Thread]}/{[p.Number]} ({elapsed}): {[
              if String.lengthGe p.Body 1 then p.Body else "[empty]"
            ]}
          </a>
        </li>
      </xml>)
    recentPosts;
  Layout.layout ("Front Page - " ^ siteName) front_page "" <xml>
    <header>
      <h1>{[siteName]}</h1>
    </header>
    <main>
      <div class="container">
        <section>
          <header>Boards</header>
          <ul class="section-body">
            {List.mapX
              (fn b => <xml><li><a link={catalog b.Id}>{[b]}</a></li></xml>)
              boards}
          </ul>
        </section>
      </div>
      <div class="container">
        <section>
          <header>About</header>
          <div class="section-body">{readme}</div>
        </section>
        <section>
          <header>News</header>
          <div class="section-body">{news}</div>
        </section>
      </div>
      <div class="container">
        <section>
          <header>Recent posts</header>
          <ul class="section-body recent_posts_list">
            {recentPosts}
          </ul>
        </section>
      </div>
    </main>
    <footer>Powered by <a href="https://github.com/steinuil/negoto">Negoto</a></footer>
  </xml>


and catalog board =
  boards <- Data.allBoards;
  case List.find (fn b => b.Id = board) boards of
  | None => error <xml>Board not found: {[board]}</xml>
  | Some board =>
    threads <- (Data.catalog' board.Id `bind` List.mapXM catalogThread);
    postForm <- catalogForm board.Id;
    layout boards (show board) catalog_page <xml>
      {postForm}
      <div class="container">{threads}</div>
    </xml>


and catalogThread thread' =
  updated <- Util.elapsed thread'.Updated;
  return <xml>
    <div class="catalog-thread">
      <figure>
        <a link={thread thread'.Id}>
          {case thread'.Files of
          | [] => <xml>link</xml>
          | file :: _ => <xml><figure>
            <img src={thumbOf file}/>
          </figure></xml>}
        </a>
      </figure>
      <div class="info">
        <time>{updated}</time>
        <span class="separator">/</span>
        {[thread'.Count - 1]} repl{if thread'.Count = 2 then <xml>y</xml> else <xml>ies</xml>}
        {if thread'.Locked then <xml><span class="separator">/</span> Locked</xml> else <xml/>}
      </div>
      <div class="description">
        <span class="subject">{[thread'.Subject]}</span>
        {if thread'.Body = "" then
          <xml/>
        else <xml>
          <span class="separator">//</span>
          <span class="post-body">{[thread'.Body]}</span>
        </xml>}
      </div>
    </div>
  </xml>


and thread id =
  t <- Data.thread id;
  case t of
  | None => error <xml>Thread not found: {[id]}</xml>
  | Some (t, posts) =>
    (*
    dynFormBody <- source "";
    dynForm <- postForm dynFormBody id;
    *)
    let
      fun pageTitle boards =
        List.find (fn board => board.Id = t.Board) boards
        |> Option.mp show
        |> Option.get ""

      val (op, posts) = case posts of
        | op :: rest => (op, rest)
        | _ => error <xml>Empty thread</xml>

      (*
      fun addToForm str =
        b <- get dynFormBody;
        set dynFormBody (b ^ str)
      *)

      fun postInfo p =
        <xml><div class="info">
          <span class="name">{[p.Nam]}</span>
          <time>{[p.Time]}</time>
          <a href={Post.link (Post.id p.Number)}>&#8470;</a><span class="ulink">{[p.Number]}</span>
          <!-- onclick={fn _ => addToForm (">>" ^ show p.Number ^ "\n")}>{[p.Number]}</span> -->
        </div></xml>

      fun threadPost' pic p =
        <xml><div class="post reply" id={Post.id p.Number}>
          {pic p.Files}
          {postInfo p}
          <div class="post-body">{p.Body}</div>
        </div></xml>

      fun threadOp pic op =
        <xml><div class="post op-post" id={Post.id op.Number}>
          {pic op.Files}
          {postInfo op}
          <div class="post-body">{op.Body}</div>
        </div></xml>

      fun staticPicture files =
        case files of
        | [] => <xml/>
        | f :: _ => <xml><a href={f.Src}>
          <img src={thumbOf f}/>
        </a></xml>

      fun dynPicture expanded files =
        let
          val toggleExp =
            exp <- get expanded;
            preventDefault;
            set expanded (not exp)

          fun image f =
            exp <- signal expanded;
            return <|
              if exp then
                <xml><img class="expanded-img" src={f.Src}/></xml>
              else
                <xml><img src={thumbOf f}/></xml>
        in
          case files of
          | [] => <xml/>
          | f :: _ => <xml><a href={f.Src} onclick={fn _ => toggleExp}>
            <noscript><img src={thumbOf f}/></noscript>
            <dyn signal={image f}/>
          </a></xml>
        end

      fun staticThreadPost p =
        body <- Post.toHtml p.Body;
        return (threadPost' staticPicture (Util.replaceField [#Body] p body))

      fun dynThreadPost p =
        threadPost' (dynPicture p.Expanded) (p -- #Expanded)

      fun toDynPost p =
        expanded <- source False;
        body <- Post.toHtml p.Body;
        return (p -- #Body ++ { Body = body, Expanded = expanded })

      fun lastPost p =
        Util.listLast p
        |> Option.mp (fn x => x.Number)
        |> Option.get 1

      fun fetchNewPosts ps =
        posts <- get ps;
        newPosts <- rpc (Data.postsSince id (lastPost posts));
        newPosts <- List.mapM toDynPost newPosts;
        set ps (List.append posts newPosts)
    in
      boards <- Data.allBoards;
      op <- toDynPost op;
      staticPosts <- List.mapXM staticThreadPost posts;
      dynPosts <- List.mapM toDynPost posts;
      dynPosts <- source dynPosts;
      staticForm <- staticThreadForm t.Id;

      layout boards (pageTitle boards) thread_page <xml>
        <header>
          [<a link={catalog t.Board}>back</a>]
          <span class="subject">{[t.Subject]}</span>
          {if t.Locked then <xml>(locked)</xml> else <xml/>}
        </header>
        <div class="container">
          {threadOp (dynPicture op.Expanded) (op -- #Expanded)}
          <noscript>{staticPosts}</noscript>
          <dyn signal={
            posts <- signal dynPosts;
            return (List.mapX dynThreadPost posts)
          }/>
        </div>
        {if t.Locked then <xml/> else
        <xml>
          <div class="static-form-container">{staticForm}</div>
          <!-- {dynForm} -->
        </xml>}
        [ <a link={catalog t.Board}>back</a>
        / <span class="ulink" onclick={fn _ => fetchNewPosts dynPosts}>update</span>
        ]
      </xml>
    end


and navigation boards =
  affiliateLinks <- Admin.links;
  let
    val boards =
      <xml><a link={front ()}>Home</a></xml>
      :: List.mp (fn { Id = id, Nam = name } =>
        <xml><a link={catalog id} title={name}>{[id]}</a></xml>)
        boards

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
    <hidden{#Board} value={show boardId}/>
    <submit action={create_thread} class="hidden-field" id={submitButton} />
  </form></xml>


and staticThreadForm (threadId : int) : transaction xbody =
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


and create_thread f =
  if strlen f.Body > 2000 then E.tooLong "Body" 2000 else
  if strlen f.Nam > 40 then E.tooLong "Name" 40 else
  if strlen f.Subject > 140 || strlen f.Subject < 1 then E.between "Subject" 1 140 else
  let
    val name = if f.Nam = "" then "Anonymous" else f.Nam

    val files =
      if blobSize (fileData f.File) > 0 then
        { File = f.File, Spoiler = f.Spoiler } :: []
      else
        E.msg "You have to post a file to start a thread"

    val thread' = f -- #File -- #Spoiler -- #Nam ++
      { Files = files, Nam = name }
  in
    id <- Data.addThread thread';
    redirect (url (thread id))
  end


and create_post f =
  if strlen f.Body > 2000 then E.tooLong "Body" 2000 else
  if strlen f.Nam > 40 then E.tooLong "Name" 40 else
  if strlen f.Body = 0 && blobSize (fileData f.File) = 0 then
    E.msg "You can't post with an empty comment and no file"
  else
  let
    val name = if f.Nam = "" then "Anonymous" else f.Nam

    val files =
      if blobSize (fileData f.File) > 0 then
        { File = f.File, Spoiler = f.Spoiler } :: []
      else
        []

    val post = f -- #Thread -- #File -- #Spoiler -- #Nam ++
      { Thread = readError f.Thread, Files = files, Nam = name }
  in
  _ <- Data.addPost post;
  redirect (url (thread post.Thread))
  end


and create_post' f =
  let val post = f -- #Spoiler ++ { Files = [] } in
    _ <- Data.addPost post;
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
      <ctextarea placeholder="Comment" source={body}/>
      <div>
        <ccheckbox source={spoiler} id={spoilerId} class="hidden-field"/>
        <label for={spoilerId} class="button">Spoiler</label>
      </div>
    </div></xml>
  end
