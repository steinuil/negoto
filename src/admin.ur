structure Log = Logger.Make(struct val section = "admin" end)


val siteName =
  Util.getM "Negoto" (KeyVal.get "siteName")


fun setSiteName name =
  KeyVal.set "siteName" name


table affLinks :
  { Link : url
  , Nam  : string }
  PRIMARY KEY Link

val links =
  queryL1 (SELECT * FROM affLinks)


fun addLink { Link = link, Nam = name } =
  dml (INSERT INTO affLinks (Link, Nam)
       VALUES ( {[bless link]}, {[name]} ))


fun deleteLink link =
  dml (DELETE FROM affLinks WHERE Link = {[link]})


val readme =
  Util.getM "replace me" (KeyVal.get "readme")


fun updateReadme body =
  KeyVal.set "readme" body


(* News *)
sequence newsItems_id

table newsItems :
  { Id      : int
  , Title   : string
  , Author  : string
  , Time    : time
  , Body    : string }
  PRIMARY KEY (Id)


type newsItem =
  { Title  : string
  , Author : string
  , Time   : time
  , Body   : string }


val news =
  query (SELECT * FROM newsItems)
    (fn { NewsItems = x } acc => return ((x -- #Id) :: acc)) []


val allNews =
  queryL1 (SELECT * FROM newsItems)


fun getNews id =
  oneOrNoRows1 (SELECT * FROM newsItems WHERE newsItems.Id = {[id]})


fun addNews { Title = title, Author = author, Body = body } =
  id <- nextval newsItems_id;
  dml (INSERT INTO newsItems (Id, Title, Author, Time, Body)
       VALUES ( {[id]}, {[title]}, {[author]}, CURRENT_TIMESTAMP, {[body]} ));
  return id


fun deleteNews (id : int) =
  dml (DELETE FROM newsItems WHERE Id = {[id]})


fun editNews id { Title = title, Body = body } =
  dml (UPDATE newsItems SET Title = {[title]}, Body = {[body]}
       WHERE Id = {[id]})



(* Admin stuff *)


open Styles
style page


fun confirmDel name _ =
  ok <- confirm ("Are you sure you want to delete " ^ name ^ "?");
  if ok then return () else preventDefault


fun deleteForm value name (act : { Id : string } -> transaction page) =
  delButton <- fresh;
  return <xml><form>
    <hidden{#Id} value={value}/>
    [<label for={delButton} class="link">delete</label>]
    <submit id={delButton} class="hidden-field"
      onclick={confirmDel name}
      action={act}/>
  </form></xml>


fun editButton [nm :: Name] [t ::: Type] [r ::: {Type}] [[nm] ~ r] (_ : eq t)
  (selected : source (option $([nm = t] ++ r)))
  (curr : $([nm = t] ++ r))
  : xbody =
  <xml>[<span class="link" onclick={fn _ =>
    el <- get selected;
    case el of
    | None => set selected (Some curr)
    | Some el =>
      if el.nm = curr.nm then
        return ()
      else
        set selected (Some curr)}>edit</span>]</xml>


fun layout (body' : xbody) : transaction page =
  user <- Account.authenticate;
  logout <- fresh;
  let
    val links = List.mp (fn (p, n) => <xml><a href={p}>{[n]}</a></xml>)
      ((url (front ()), "front") :: (url (boards ()), "boards") ::
       (url (news_items ()), "news") :: (url (site_settings ()), "site settings") :: [])

    val settings = <xml><a link={settings ()}>{[user]}</a></xml>
      :: <xml><form>
           <label class="link" for={logout}>log out</label>
           <submit id={logout} action={log_out} class="hidden-field"/>
         </form></xml>
      :: []
  in
    Layout.layout "Admin" page "Admin page" <xml>
      <header><nav>{Layout.navMenu links} {Layout.navMenu settings}</nav></header>
      <main><div class="container">{body'}</div></main>
    </xml>
  end


and boards () =
  tags <- Data.allTags;
  selectedBoard <- source None;
  let
    val slugEditor =
      sel <- signal selectedBoard;
      case sel of
      | None => return <xml/>
      | Some board =>
        return <xml><form class="edit-area">
          <hidden{#Nam} value={board.Nam}/>
          <textbox{#Slug} required placeholder="Slug" value={board.Slug}/>
          <submit value="Edit slug" action={edit_slug}/>
        </form></xml>

    fun boardRow b =
      del <- deleteForm b.Nam ("/" ^ b.Nam ^ "/") delete_board;
      delButton <- fresh;
      return <xml><tr>
        <td><a link={board b.Nam}>{[b.Nam]}</a></td>
        <td>{[b.Slug]}</td>
        <td>{editButton [#Nam] selectedBoard b} {del}</td>
      </tr></xml>
  in
    rows <- List.mapXM boardRow tags;
    layout <xml><section>
      <header>Add a board</header>
      <form>
        <textbox{#Nam} required placeholder="Name"/>
        <textbox{#Slug} required placeholder="Slug"/>
        <submit value="Create board" action={create_board}/>
      </form>
    </section><section>
      <header>Boards</header>
      <table>
        <tr>
          <th>Name</th>
          <th>Slug</th>
          <th/>
        </tr>
        {rows}
      </table>
      <dyn signal={slugEditor}/>
    </section></xml>
  end


(* TODO: validation *)
and create_board f =
  admin <- Account.authenticate;
  Data.newTag f;
  Log.info (admin ^ " created board /" ^ f.Nam ^ "/ - " ^ f.Slug);
  redirect (url (boards ()))


and delete_board { Id = name } =
  admin <- Account.authenticate;
  Data.deleteTag name;
  Log.info (admin ^ " deleted board /" ^ name ^ "/");
  redirect (url (boards ()))


and edit_slug f =
  admin <- Account.authenticate;
  Data.editSlug f;
  Log.info (admin ^ " changed board /" ^ f.Nam ^ "/'s slug to " ^ f.Slug);
  redirect (url (boards ()))


and board name =
  t <- Data.catalogByTag' name;
  case t of None => error <xml>Board not found</xml> | Some threads =>
    rows <- List.mapXM
      (fn { Id = id, Subject = subject, Locked = locked, ... } =>
        let
          val lockAction = if locked then unlock_thread else lock_thread

          fun button labl act confirm =
            button' <- fresh;
            return <xml><form class="edit-area">
              <hidden{#Id} value={show id}/>
              <hidden{#Tag} value={name}/> <!-- to redirect you back here -->
              [<label for={button'} class="link">{[labl]}</label>]
              <submit id={button'} onclick={confirm} class="hidden-field" action={act}/>
            </form></xml>
        in
          delButton <- button "delete" delete_thread (confirmDel subject);
          lockButton <- button ((if locked then "un" else "") ^ "lock thread")
                               lockAction (fn _ => return ());
          return <xml><tr>
            <td><a link={thread id}>{[id]}</a></td>
            <td>{[subject]}</td>
            <td>{lockButton} {delButton}</td>
          </tr></xml>
        end)
        threads;
    layout <xml><section>
      <header>Manage threads</header>
      <table>
        <tr><th>ID</th><th>Subject</th><th/></tr>
        {rows}
      </table>
    </section></xml>


and delete_thread { Id = id, Tag = tag } =
  admin <- Account.authenticate;
  Data.deleteThread (readError id);
  Log.info (admin ^ " deleted thread " ^ id);
  redirect (url (board tag))


and unlock_thread { Id = id, Tag = tag } =
  admin <- Account.authenticate;
  Data.unlockThread (readError id);
  Log.info (admin ^ " unlocked thread " ^ id);
  redirect (url (board tag))


and lock_thread { Id = id, Tag = tag } =
  admin <- Account.authenticate;
  Data.lockThread (readError id);
  Log.info (admin ^ " locked thread " ^ id);
  redirect (url (board tag))


and thread tid =
  x <- Data.threadById tid;
  case x of None => error <xml>Thread not found</xml> | Some (_, posts) =>
  layout <xml><table>
    <tr><th>ID</th><th>Files</th></tr>
    {List.mapX (fn { Id = id, Files = files, ... } =>
      <xml><tr>
        <td>{[id]}</td>
        <td>{List.mapX (fn file => <xml><form>
              <hidden{#Hash} value={file.Hash}/>
              <hidden{#Nam} value={file.Nam}/>
              <hidden{#Mime} value={file.Mime}/>
              <hidden{#Spoiler} value={show file.Spoiler}/>
              <hidden{#Thread} value={show tid}/>
              <submit value={"Delete file " ^ file.Nam}
                onclick={confirmDel file.Nam} action={delete_file}/>
            </form></xml>
          ) files}</td>
        <td><form>
          <hidden{#Id} value={show id}/>
          <hidden{#Thread} value={show tid}/>
          <submit value="Delete post" onclick={confirmDel (show id)}
            action={delete_post}/>
        </form></td>
      </tr></xml>) posts}
  </table></xml>


and delete_post { Id = id, Thread = thread' } =
  admin <- Account.authenticate;
  let val t = readError thread' in
    Data.deletePost t (readError id);
    Log.info (admin ^ " deleted post " ^ id ^ "on thread " ^ thread');
    redirect (url (thread t))
  end


and delete_file file =
  admin <- Account.authenticate;
  Data.deleteFile (file -- #Thread -- #Spoiler ++ { Spoiler = readError file.Spoiler });
  Log.info (admin ^ " deleted file " ^ file.Hash);
  redirect (url (thread (readError file.Thread)))


and news_items () =
  n <- allNews;
  user <- Account.authenticate;
  selectedNews <- source None;
  rows <- List.mapXM (fn n =>
    del <- deleteForm (show n.Id) n.Title delete_news_item;
    return <xml>
      <tr>
        <td>{[n.Title]}</td>
        <td>{[n.Author]}</td>
        <td>{[n.Time]}</td>
        <td>{editButton [#Id] selectedNews n} {del}</td>
      </tr>
    </xml>) n;
  layout <xml><section>
    <header>Add news</header>
    <form>
      <hidden{#Author} value={user}/>
      <textbox{#Title} placeholder="Title" required/><br/>
      <textarea{#Body} placeholder="Body" required/><br/>
      <submit action={create_news_item} value="Post news"/>
    </form>
  </section><section>
    <header>News</header>
    <table>
      <tr>
        <th>Title</th>
        <th>Author</th>
        <th>Time</th>
        <th/>
      </tr>
      {rows}
   </table>
   <dyn signal={
    sel <- signal selectedNews;
    case sel of
    | None => return <xml/>
    | Some news =>
      return <xml><form class="edit-area" >
        <hidden{#Id} value={show news.Id}/>
        <textbox{#Title} placeholder="Title" required value={news.Title}/>
        <textarea{#Body} required placeholder="Body">{[news.Body]}</textarea>
        <submit value="Edit news item" action={edit_news_item}/>
      </form></xml>}/>
  </section>
</xml>


and create_news_item x =
  admin <- Account.authenticate;
  id <- addNews x;
  Log.info (admin ^ " added newsItem " ^ show id ^ ": " ^ x.Title);
  redirect (url (news_items ()))


and delete_news_item { Id = id } =
  admin <- Account.authenticate;
  deleteNews (readError id);
  Log.info (admin ^ " deleted newsItem " ^ id);
  redirect (url (news_items ()))


and edit_news_item f =
  admin <- Account.authenticate;
  editNews (readError f.Id) (f -- #Id);
  Log.info (admin ^ " edited newsItem " ^ f.Id);
  redirect (url (news_items ()))


and site_settings () =
  (admin, role) <- Account.requireLevel Account.Admin;
  r <- readme;
  maxThreads <- Data.maxThreads;
  themes <- Layout.allThemes;
  siteName <- siteName;
  selectedTheme <- source None;
  accounts <- Account.all;
  accountTable <- List.mapXM
    (fn a =>
      del <- deleteForm a.Nam a.Nam delete_account;
      return <xml><tr>
        <td>{[a.Nam]}</td>
        <td>{[a.Role]}</td>
        <td>{del}</td>
      </tr></xml>)
    accounts;
  themeTable <- List.mapXM
    (fn t =>
      del <- deleteForm t.Filename t.Nam delete_theme;
      return <xml><tr>
        <td>{[t.Nam]}</td>
        <td>{[t.Filename]}</td>
        <td>{editButton [#Filename] selectedTheme t} {del}</td>
      </tr></xml>)
    themes;
  layout <xml><section>
  <!-- SITE NAME AND LINKS -->
    <header>Site name</header>
    <form>
      <textbox{#Nam} value={siteName}/>
      <submit value="Set site name" action={set_site_name}/>
    </form>
  </section><section>
    <header>Affiliate links</header>
    <form>
      <textbox{#Nam} placeholder="Name"/>
      <url{#Link} placeholder="URL"/>
      <submit value="Add link" action={add_affiliate_link}/>
    </form>
  </section><section>
    <header>Threads per board</header>
    <form>
      <number{#Max} value={float maxThreads} min={5.0} max={200.0} step={1.0}/>
      <submit value="Set max threads" action={set_max_threads}/>
    </form>
  </section><section>
    <header>Readme</header>
    <div>{Post.toHtml' r}</div>
    <form>
      <textarea{#Body} required placeholder="Readme">{[r]}</textarea><br/>
      <submit value="Edit readme" action={edit_readme}/>
    </form>
  </section><section>
  <!-- ACCOUNTS -->
    <header>Add an account</header>
    <form>
      <textbox{#Nam} placeholder="Name"/>
      <password{#Pass} placeholder="Password"/>
      <select{#Role}>
        <option value={show Account.Moderator}>Moderator</option>
        {if role < Account.Owner then <xml/> else
          <xml><option value={show Account.Admin}>Administrator</option></xml>}
      </select>
      <submit value="Add" action={add_account}/>
    </form>
  </section><section>
    <header>Manage accounts</header>
    <table>
      <tr><th>Name</th><th>Role</th><th/></tr>
      {accountTable}
    </table>
  </section><section>
  <!-- THEMES -->
    <header>Add a theme</header>
    <form>
      <textbox{#Nam} placeholder="Name"/>
      <textbox{#TabColor} placeholder="Tab color (on mobile Chrome)"/>
      <textbox{#Filename} placeholder="Desired filename (without .css)"/>
      <upload{#Css}/>
      <submit value="Upload theme" action={add_theme}/>
    </form>
  </section><section>
    <header>Themes</header>
    <table>
      <tr><th>Name</th><th>Filename</th><th/></tr>
      {themeTable}
    </table>
    <dyn signal={
      theme <- signal selectedTheme;
      case theme of
      | None => return <xml/>
      | Some theme =>
        return <xml><form class="edit-area">
          <hidden{#Filename} value={theme.Filename}/>
          <textbox{#Nam} placeholder="Name" value={theme.Nam}/><br/>
          <textbox{#TabColor} placeholder="Tab color" value={theme.TabColor}/><br/>
          <submit value="Edit theme" action={edit_theme}/>
        </form></xml>}/>
  </section><section>
    <header>Default theme</header>
    <form>
      <select{#Theme}>
        {List.mapX (fn { Nam = name, Filename = fname, ... } =>
          <xml><option value={fname}>{[name]}</option></xml>) themes}
      </select>
      <submit value="Set default theme" action={set_default_theme}/>
    </form>
  </section></xml>


and set_site_name { Nam = name } =
  (admin, _) <- Account.requireLevel Account.Admin;
  setSiteName name;
  Log.info (admin ^ " set the site name to " ^ name);
  redirect (url (site_settings ()))


and add_affiliate_link f =
  (admin, _) <- Account.requireLevel Account.Admin;
  addLink f;
  Log.info (admin ^ " added link " ^ f.Link);
  redirect (url (site_settings ()))


and add_account { Nam = name, Pass = pass, Role = role } =
  (admin, role') <- Account.requireLevel Account.Admin;
  let val role : Account.role = readError role in
  if role' > role then
    Account.create name pass role;
    Log.info (admin ^ " created account " ^ name);
    redirect (url (site_settings ()))
  else
    error <xml>You don't have permission to perform this action.</xml>
  end


and delete_account { Id = name } =
  (admin, role') <- Account.requireLevel Account.Admin;
  role <- Account.roleOf name;
  let val role = case role of
    | None => error <xml>The queried account doesn't exist.</xml>
    | Some role => role in
  if role' > role then
    Account.delete name;
    Log.info (admin ^ " deleted account " ^ name);
    redirect (url (site_settings ()))
  else
    error <xml>You don't have permission to perform this action.</xml>
  end


and add_theme f =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.addTheme (f -- #Css) f.Css;
  Log.info (admin ^ " uploaded theme " ^ f.Filename);
  redirect (url (site_settings ()))


and edit_theme f =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.editTheme f;
  Log.info (admin ^ " edited theme " ^ f.Filename);
  redirect (url (site_settings ()))


and delete_theme { Id = fname } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.deleteTheme fname;
  Log.info (admin ^ " edited theme " ^ fname);
  redirect (url (site_settings ()))


and set_default_theme { Theme = theme } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.setDefaultTheme theme;
  Log.info (admin ^ " set the default theme to " ^ theme);
  redirect (url (site_settings ()))


and set_max_threads { Max = max } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Data.setMaxThreads (ceil max);
  Log.info (admin ^ " set the max threads to " ^ show (ceil max));
  redirect (url (site_settings ()))


and edit_readme { Body = body } =
  (admin, _) <- Account.requireLevel Account.Admin;
  updateReadme body;
  Log.info (admin ^ " edited the readme");
  redirect (url (site_settings ()))


and settings () : transaction page =
  layout <xml>
  </xml>


and front () : transaction page =
  admin <- Account.authenticateOpt;
  case admin of
  | Some name =>
    layout <xml>
      Welcome to the admin page, {[name]}
    </xml>
  | None =>
    Layout.layout "Login" page "Login page" <xml><main><div class="container"><form>
      <textbox{#Nam} placeholder="Name" required/><br/>
      <password{#Password} placeholder="password" required/><br/>
      <submit value="Log in" action={log_in}/>
    </form></div></main></xml>


and log_in { Nam = name, Password = pass } =
  Account.logIn name pass;
  redirect (url (front ()))


and log_out () =
  Account.logOutCurrent;
  redirect (url (front ()))
