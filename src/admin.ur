structure Log = Logger.Make(struct val section = "admin" end)


val readme =
  x <- KeyVal.get "readme";
  return (Option.get "replace me" x)


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
  ok <- confirm ("Do you really want to delete " ^ name ^ "?");
  if ok then return () else preventDefault


fun layout (body' : xbody) : transaction page =
  user <- Account.authenticate;
  logout <- fresh;
  Layout.layout "Admin" page "Admin page" <xml>
    <header><nav>[
      <a href={url (front ())}>front</a> /
      <a href={url (boards ())}>boards</a> /
      <a href={url (news_items ())}>news</a> /
      <a href={url (readme_text ())}>readme</a>
    ] [
      {[user]} /
      <a href={url (settings ())}>settings</a> /
      <form><label class="link" for={logout}>logout</label><submit id={logout} action={log_out} class="hidden-field"/></form>
    ]</nav></header>
    <main><div class="container">{body'}</div></main>
  </xml>


and boards () =
  tags <- Data.allTags;
  layout <xml>
    <table>
      <tr>
        <th>Name</th>
        <th>Slug</th>
      </tr>
      {List.mapX (fn { Nam = name, Slug = slug } =>
        <xml><tr><td><a href={url (board name)}>{[name]}</a></td>
          <form><hidden{#Nam} value={name}/>
            <td><textbox{#Slug} required placeholder="Slug" value={slug}/></td>
            <td><submit value="Edit slug" action={edit_slug}/></td>
          </form>
          <td><form><hidden{#Nam} value={name}/>
            <submit value="Delete board" action={delete_board}
              onclick={confirmDel ("/" ^ name ^ "/")}/>
          </form></td>
        </tr></xml>)
        tags}
      <form>
        <tr>
          <td><textbox{#Nam} required placeholder="Name"/></td>
          <td><textbox{#Slug} required placeholder="Slug"/></td>
          <td><submit value="Create board" action={create_board}/></td>
        </tr>
      </form>
    </table>
  </xml>


(* TODO: validation *)
and create_board f =
  admin <- Account.authenticate;
  Data.newTag f;
  Log.info (admin ^ " created board /" ^ f.Nam ^ "/ - " ^ f.Slug);
  redirect (url (boards ()))


and delete_board { Nam = name } =
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
  layout <xml><table>
    <tr><th>ID</th><th>Subject</th></tr>
    {List.mapX (fn { Id = id, Subject = subject, Locked = locked, ... } =>
      <xml><tr>
        <td><a href={url <| thread id}>{[id]}</a></td><td>{[subject]}</td>
        <td><form>
          <hidden{#Id} value={show id}/>
          <hidden{#Tag} value={name}/>
          <submit value="Delete thread" onclick={confirmDel subject}
            action={delete_thread}/>
        </form></td>
        <td>
          {if locked then
            <xml><form>
              <hidden{#Id} value={show id}/>
              <hidden{#Tag} value={name}/>
              <submit value="Unlock thread" action={unlock_thread}/>
            </form></xml>
          else
            <xml><form>
              <hidden{#Id} value={show id}/>
              <hidden{#Tag} value={name}/>
              <submit value="Lock thread" action={lock_thread}/>
            </form></xml>}
        </td>
      </tr></xml>)
      threads}
  </table></xml>


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
        <td>{List.mapX (fn file =>
            <xml><form>
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
  layout <xml><dyn signal={
    sel <- signal selectedNews;
    case sel of
    | None => return <xml/>
    | Some news =>
      return <xml><form>
        <hidden{#Id} value={show news.Id}/>
        <textbox{#Title} placeholder="Title" required value={news.Title}/><br/>
        <textarea{#Body} required placeholder="Body">{[news.Body]}</textarea><br/>
        <submit value="Edit news item" action={edit_news_item}/>
      </form>
      <form>
        <hidden{#Id} value={show news.Id}/>
        <submit value="Delete item"
          onclick={confirmDel news.Title}
          action={delete_news_item}/>
      </form>
      </xml>
  }/><table>
    <tr><th class="title-column">Title</th><th class="name-column">Author</th><th class="time-column">Time</th></tr>
    {List.mapX (fn n => <xml>
        <tr onclick={fn _ =>
          news <- get selectedNews;
          case news of
          | None => set selectedNews (Some n)
          | Some { Id = id, ... } =>
            if id = n.Id then
              set selectedNews None
            else
              return ()
        }>
          <td>{[n.Title]}</td>
          <td>{[n.Author]}</td>
          <td>{[n.Time]}</td>
        </tr>
      </xml>) n}
  </table><form>
    <hidden{#Author} value={user}/>
    <textbox{#Title} placeholder="Title" required/><br/>
    <textarea{#Body} placeholder="Body" required/><br/>
    <submit action={create_news_item} value="Post news"/>
  </form></xml>


and news_item id =
  n <- getNews id;
  case n of None => error <xml>No such news item</xml> | Some news =>
  layout <xml><form>
    <hidden{#Id} value={show id}/>
    <textbox{#Title} placeholder="Title" required value={news.Title}/><br/>
    <textarea{#Body} required placeholder="Body">{[news.Body]}</textarea><br/>
    <submit value="Edit news item" action={edit_news_item}/>
  </form></xml>


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


and readme_text () =
  r <- readme;
  layout <xml>
    <div>{Post.toHtml' r}</div>
    <form>
      <textarea{#Body} required placeholder="Readme">{[r]}</textarea><br/>
      <submit value="Edit readme" action={edit_readme}/>
    </form>
  </xml>


and edit_readme { Body = body } =
  admin <- Account.authenticate;
  updateReadme body;
  Log.info (admin ^ " edited the readme");
  redirect (url (readme_text ()))


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
