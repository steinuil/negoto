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
  { Id     : int
  , Title  : string
  , Author : string
  , Time   : time
  , Body   : string }
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
structure E = Error
style page
style login


fun confirmDel name _ =
  ok <- confirm ("Are you sure you want to delete " ^ name ^ "?");
  if ok then return () else preventDefault


fun deleteForm value name (act : { Id : string } -> transaction page) =
  delButton <- fresh;
  return <xml><form>
    <hidden{#Id} value={value}/>
    [<label for={delButton} class="ulink">delete</label>]
    <submit id={delButton} class="hidden-field"
      onclick={confirmDel name}
      action={act}/>
  </form></xml>


fun editButton [nm :: Name] [t ::: Type] [r ::: {Type}] [[nm] ~ r] (_ : eq t)
  (selected : source (option $([nm = t] ++ r)))
  (curr : $([nm = t] ++ r))
  : xbody =
  <xml>[<span class="ulink" onclick={fn _ =>
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

    val settings = <xml><a link={your_settings ()}>{[user]}</a></xml>
      :: <xml><form>
           <label class="ulink" for={logout}>log out</label>
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
  boards <- Data.allBoards;
  selectedBoard <- source None;
  let
    val nameEditor =
      sel <- signal selectedBoard;
      case sel of
      | None => return <xml/>
      | Some board =>
        return <xml><form class="edit-area">
          <hidden{#Id} value={board.Id}/>
          <textbox{#Nam} required placeholder="Name" value={board.Nam}/>
          <submit value="Edit name" action={edit_name}/>
        </form></xml>

    fun boardRow b =
      del <- deleteForm b.Id ("/" ^ b.Id ^ "/") delete_board;
      return <xml><tr>
        <td><a link={board b.Id}>{[b.Id]}</a></td>
        <td>{[b.Nam]}</td>
        <td>{editButton [#Id] selectedBoard b} {del}</td>
      </tr></xml>
  in
    rows <- List.mapXM boardRow boards;
    layout <xml><section>
      <header>Add a board</header>
      <form>
        <textbox{#Id} required placeholder="Id"/>
        <textbox{#Nam} required placeholder="Name"/>
        <submit value="Create board" action={create_board}/>
      </form>
    </section><section>
      <header>Boards</header>
      <table>
        <tr>
          <th>Id</th>
          <th>Name</th>
          <th/>
        </tr>
        {rows}
      </table>
      <dyn signal={nameEditor}/>
    </section></xml>
  end


(* TODO: validation *)
and create_board f =
  if strlen f.Nam < 1 then E.length0 "Name" else
  if E.notBetween f.Id 1 10 then E.between "Id" 1 10 else
  admin <- Account.authenticate;
  Data.addBoard f;
  Log.info (admin ^ " created board /" ^ f.Id ^ "/ - " ^ f.Nam);
  redirect (url (boards ()))


and delete_board { Id = name } =
  admin <- Account.authenticate;
  Data.deleteBoard name;
  Log.info (admin ^ " deleted board /" ^ name ^ "/");
  redirect (url (boards ()))


and edit_name f =
  if strlen f.Nam < 1 then E.length0 "Name" else
  admin <- Account.authenticate;
  Data.editBoardName f;
  Log.info (admin ^ " changed board /" ^ f.Id ^ "/'s name to " ^ f.Nam);
  redirect (url (boards ()))


and board board =
  t <- Data.catalog board;
  case t of None => error <xml>Board not found</xml> | Some threads =>
    rows <- List.mapXM
      (fn { Id = id, Subject = subject, Locked = locked, ... } =>
        let fun button labl act confirm =
          button' <- fresh;
          return <xml><form>
            <hidden{#Id} value={show id}/>
            <hidden{#Board} value={board}/> <!-- to redirect you back here -->
            [<label for={button'} class="ulink">{[labl]}</label>]
            <submit id={button'} onclick={confirm} class="hidden-field" action={act}/>
          </form></xml>
        in
          delButton <- button "delete" delete_thread (confirmDel subject);
          lockButton <- button ((if locked then "un" else "") ^ "lock thread")
                               toggle_thread_lock (fn _ => return ());
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


and delete_thread { Id = id, Board = b } =
  admin <- Account.authenticate;
  Data.deleteBoard (readError id);
  Log.info (admin ^ " deleted thread " ^ id);
  redirect (url (board b))


and toggle_thread_lock { Id = id, Board = b } =
  admin <- Account.authenticate;
  Data.toggleThreadLock (readError id);
  Log.info (admin ^ " toggled lock on " ^ id);
  redirect (url (board b))


and thread tid =
  x <- Data.thread tid;
  case x of None => error <xml>Thread not found</xml> | Some (thread', posts) =>
  selectedPost <- source None;
  postTable <- List.mapXM (fn p =>
    delButton <- fresh;
    return <xml><tr>
      <td>{[p.Number]}</td>
      <td>{[p.Nam]}</td>
      <td>
        {editButton [#Id] selectedPost p}
        <form>
          <hidden{#Id} value={show p.Id}/>
          <hidden{#Thread} value={show tid}/>
          [<label for={delButton} class="ulink">delete</label>]
          <submit id={delButton} onclick={confirmDel (show p.Id)}
            class="hidden-field" action={delete_post}/>
        </form>
      </td>
    </tr></xml>)
    posts;
  layout <xml><section>
    [<a link={board thread'.Board}>go back to the thread list</a>]
  </section><section>
    <header>Manage posts of thread {[tid]}</header>
    <table>
      <tr><th>Number</th><th>Name</th><th/></tr>
      {postTable}
    </table>
    <dyn signal={
      post <- signal selectedPost;
      case post of None => return <xml/> | Some post =>
      return <xml><form class="edit-area">
        <select{#Id}>
          {List.mapX (fn file =>
            <xml><option value={show file.Handle}>{[file.Fname]}</option></xml>)
            post.Files}
        </select>
        <hidden{#Thread} value={show tid}/>
        <submit action={delete_file} value="Delete file"/>
      </form></xml>
    }/>
  </section></xml>


and delete_post { Id = id, Thread = thread' } =
  admin <- Account.authenticate;
  Data.deletePost (readError id);
  Log.info (admin ^ " deleted post " ^ id);
  redirect (url (thread (readError thread')))


and delete_file { Id = handle, Thread = thread' } =
  admin <- Account.authenticate;
  Data.deleteFile (readError handle);
  Log.info (admin ^ " deleted file " ^ handle);
  redirect (url (thread (readError thread')))


and news_items () =
  n <- allNews;
  user <- Account.authenticate;
  selectedNews <- source None;
  rows <- List.mapXM (fn n =>
    del <- deleteForm (show n.Id) n.Title delete_news_item;
    return <xml><tr>
      <td>{[n.Title]}</td>
      <td>{[n.Author]}</td>
      <td>{[n.Time]}</td>
      <td>{editButton [#Id] selectedNews n} {del}</td>
    </tr></xml>) n;
  layout <xml><section>
    <header>Add news</header>
    <form>
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
  if strlen x.Title < 1 then E.length0 "Title" else
  if strlen x.Body < 1 then E.length0 "Body" else
  admin <- Account.authenticate;
  id <- addNews (x ++ { Author = admin });
  Log.info (admin ^ " added newsItem " ^ show id ^ ": " ^ x.Title);
  redirect (url (news_items ()))


and delete_news_item { Id = id } =
  admin <- Account.authenticate;
  deleteNews (readError id);
  Log.info (admin ^ " deleted newsItem " ^ id);
  redirect (url (news_items ()))


and edit_news_item f =
  if strlen f.Title < 1 then E.length0 "Title" else
  if strlen f.Body < 1 then E.length0 "Body" else
  admin <- Account.authenticate;
  editNews (readError f.Id) (f -- #Id);
  Log.info (admin ^ " edited newsItem " ^ f.Id);
  redirect (url (news_items ()))


and site_settings () =
  (admin, role) <- Account.requireLevel Account.Admin;
  r <- readme;
  r <- Post.toHtml r;
  maxThreads <- Data.maxThreads;
  maxPosts <- Data.maxPosts;
  siteName <- siteName;
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
  themes <- Layout.allThemes;
  selectedTheme <- source None;
  themeTable <- List.mapXM
    (fn t =>
      del <- deleteForm (show t.Handle) t.Nam delete_theme;
      return <xml><tr>
        <td>{[t.Nam]}</td>
        <td>{editButton [#Handle] selectedTheme t} {del}</td>
      </tr></xml>)
    themes;
  links' <- links;
  linkTable <- List.mapXM
    (fn l =>
      del <- deleteForm (show l.Link) l.Nam delete_affiliate_link;
      return <xml><tr>
        <td>{[l.Nam]}</td>
        <td>{[l.Link]}</td>
        <td>{del}</td>
      </tr></xml>)
      links';
  banners <- Layout.allBanners;
  bannerTable <- List.mapXM
    (fn b =>
      del <- deleteForm (show b.Handle) (show b.Handle) delete_banner;
      return <xml><tr>
        <td><img width={300} height={100} src={b.Link}/></td>
        <td>{del}</td>
      </tr></xml>)
    banners;
  layout <xml><section>
  <!-- SITE NAME AND LINKS -->
    <header>Site name</header>
    <form>
      <textbox{#Nam} value={siteName}/>
      <submit value="Set site name" action={set_site_name}/>
    </form>
  </section><section>
    <header>Threads per board</header>
    <form>
      <number{#Max} value={float maxThreads} min={5.0} max={200.0} step={1.0}/>
      <submit value="Set max threads" action={set_max_threads}/>
    </form>
  </section><section>
    <header>Posts per thread</header>
    <form>
      <number{#Max} value={float maxPosts} min={50.0} max={10000.0} step={1.0}/>
      <submit value="Set max threads" action={set_max_posts}/>
    </form>
  </section><section>
    <header>Readme</header>
    <div>{r}</div>
    <form>
      <textarea{#Body} required placeholder="Readme">{[r]}</textarea><br/>
      <submit value="Edit readme" action={edit_readme}/>
    </form>
  </section><section>
  <!-- LINKS -->
    <header>Add a link</header>
    <form>
      <textbox{#Nam} placeholder="Name"/>
      <url{#Link} placeholder="URL"/>
      <submit value="Add link" action={add_affiliate_link}/>
    </form>
  </section><section>
    <header>Manage links</header>
    <table>
      <tr><th>Name</th><th>Link</th><th/></tr>
      {linkTable}
    </table>
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
      <upload{#Css}/>
      <submit value="Upload theme" action={add_theme}/>
    </form>
  </section><section>
    <header>Themes</header>
    <table>
      <tr><th>Name</th><th/></tr>
      {themeTable}
    </table>
    <dyn signal={
      theme <- signal selectedTheme;
      case theme of
      | None => return <xml/>
      | Some theme =>
        return <xml><form class="edit-area">
          <hidden{#Handle} value={show theme.Handle}/>
          <textbox{#Nam} placeholder="Name" value={theme.Nam}/><br/>
          <textbox{#TabColor} placeholder="Tab color" value={theme.TabColor}/><br/>
          <submit value="Edit theme" action={edit_theme}/>
        </form></xml>}/>
  </section><section>
    <header>Default theme</header>
    <form>
      <select{#Theme}>
        {List.mapX (fn { Nam = name, Handle = handle, ... } =>
          <xml><option value={show handle}>{[name]}</option></xml>) themes}
      </select>
      <submit value="Set default theme" action={set_default_theme}/>
    </form>
  </section><section>
    <header>Add a banner</header>
    The banner's size should be 300x100px, if not it will not display correctly.
    <form>
      <upload{#File}/>
      <submit value="Upload banner" action={add_banner}/>
    </form>
  </section><section>
    <header>Manage banners</header>
    <table>
      <tr><th>Image</th><th/></tr>
      {bannerTable}
    </table>
  </section></xml>


and set_site_name { Nam = name } =
  if strlen name < 1 then E.length0 "Name" else
  (admin, _) <- Account.requireLevel Account.Admin;
  setSiteName name;
  Log.info (admin ^ " set the site name to " ^ name);
  redirect (url (site_settings ()))


and add_affiliate_link f =
  if strlen f.Nam < 1 then E.length0 "Name" else
  if strlen (show f.Link) < 10 then E.length "Link" 10 else
  (admin, _) <- Account.requireLevel Account.Admin;
  addLink f;
  Log.info (admin ^ " added link " ^ f.Link);
  redirect (url (site_settings ()))


and delete_affiliate_link { Id = link } =
  (admin, _) <- Account.requireLevel Account.Admin;
  deleteLink (bless link);
  Log.info (admin ^ " deleted link " ^ link);
  redirect (url (site_settings ()))


and add_account { Nam = name, Pass = pass, Role = role } =
  if E.notBetween name 6 24 then E.between "Name" 6 24 else
  if strlen pass < 8 then E.length "Password" 8 else
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
  if strlen f.TabColor < 1 then E.length0 "Tab Color" else
  if strlen f.Nam < 1 then E.length0 "Name" else
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.addTheme (f -- #Css) f.Css;
  Log.info (admin ^ " uploaded theme " ^ f.Nam);
  redirect (url (site_settings ()))


and edit_theme f =
  if strlen f.TabColor < 1 then E.length0 "Tab Color" else
  if strlen f.Nam < 1 then E.length0 "Name" else
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.editTheme (readError f.Handle) (f -- #Handle);
  Log.info (admin ^ " edited theme " ^ f.Nam);
  redirect (url (site_settings ()))


and delete_theme { Id = handle } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.deleteTheme (readError handle);
  Log.info (admin ^ " edited theme " ^ handle);
  redirect (url (site_settings ()))


and set_default_theme { Theme = handle } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.setDefaultTheme (readError handle);
  Log.info (admin ^ " set the default theme to " ^ handle);
  redirect (url (site_settings ()))


and set_max_threads { Max = max } =
  let val max = ceil max in
  if max < 1 then E.msg "You can't set the maximum number of threads to 0" else
  if max > 100 then E.msg "You can't set the maximum number of threads that high" else
  (admin, _) <- Account.requireLevel Account.Admin;
  Data.setMaxThreads max;
  Log.info (admin ^ " set the max threads to " ^ show max);
  redirect (url (site_settings ()))
  end


and set_max_posts { Max = max } =
  let val max = ceil max in
  if max < 1 then E.msg "You can't set the maximum number of posts to 0" else
  if max > 10000 then E.msg "You really shouldn't set the maximum number of posts that high" else
  (admin, _) <- Account.requireLevel Account.Admin;
  Data.setMaxPosts max;
  Log.info (admin ^ " set the max posts to " ^ show max);
  redirect (url (site_settings ()))
  end


and edit_readme { Body = body } =
  if strlen body < 1 then E.length0 "The readme" else
  (admin, _) <- Account.requireLevel Account.Admin;
  updateReadme body;
  Log.info (admin ^ " edited the readme");
  redirect (url (site_settings ()))


and add_banner { File = banner } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.addBanner banner;
  Log.info (admin ^ " added banner " ^ Option.get "<unnamed>" (fileName banner));
  redirect (url (site_settings ()))


and delete_banner { Id = handle } =
  (admin, _) <- Account.requireLevel Account.Admin;
  Layout.deleteBanner (readError handle);
  Log.info (admin ^ " deleted banner " ^ handle);
  redirect (url (site_settings ()))


and your_settings () : transaction page =
  admin <- Account.authenticate;
  logOutButton <- fresh;
  layout <xml><section>
    <header>Change your password</header>
    <form>
      <hidden{#Nam} value={admin}/>
      <password{#OldPass} placeholder="Old password" required/>
      <password{#Pass} placeholder="New password" required/>
      <password{#Pass2} placeholder="New password again" required/>
      <submit value="Change" action={change_password}/>
    </form>
  </section><section>
    <header>Invalidate your access tokens</header>
    If you you lost access to a device on which you're logged into this website,
    or if you forgot to log out after using a public device,
    <form class="inline-form">
      [<label for={logOutButton} class="ulink">click this link</label>]
      <submit action={log_out_others} class="hidden-field" id={logOutButton}/>
    </form>
    to invalidate all other sessions on your account and automatically login
    again on this one.
  </section></xml>


and change_password { Nam = name, OldPass = oldPass, Pass = pass, Pass2 = pass2 } =
  admin <- Account.authenticate;
  if name <> admin then E.msg "You can't change someone else's password" else
  if pass <> pass2 then E.msg "The new passwords don't match" else
  if strlen pass < 8 then E.length "Password" 8 else
  Account.changePassword name oldPass pass;
  Log.info (admin ^  " changed their password");
  redirect (url (your_settings ()))


and log_out_others () =
  admin <- Account.authenticate;
  Account.invalidateAndRehash;
  redirect (url (your_settings ()))


and front () : transaction page =
  admin <- Account.authenticateOpt;
  case admin of
  | Some name =>
    layout <xml>
      Welcome to the admin page, {[name]}
    </xml>
  | None =>
    Layout.layout "Login" page "Login page" <xml><main><div class="container login"><form>
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
