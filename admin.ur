structure Log = Logger.Make(struct val section = "admin" end)


(* Readme *)
table readmeT :
  { Body    : string
  , Updated : time }


val readme =
  oneRow1 (SELECT * FROM readmeT)


fun updateReadme body =
  dml (UPDATE readmeT SET Body = {[body]}, Updated = CURRENT_TIMESTAMP
       WHERE TRUE)


(* News *)
sequence newsItems_id

table newsItems :
  { Id      : int
  , Title   : string
  , Author  : string
  , Time    : time
  , Body    : string }
  PRIMARY KEY (Id)


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
table admins :
  { Nam : string }


fun confirmDel name _ =
  ok <- confirm ("Do you really want to delete " ^ name ^ "?");
  if ok then return () else preventDefault


fun layout (body' : xbody) : transaction page =
  return <xml>
    <head>
      <title>Admin</title>
    </head>
    <body>
      <nav><ul>
        <a href={url (boards ())}>boards</a>
        <a href={url (news_items ())}>news</a>
        <a href={url (readme_text ())}>readme</a>
      </ul></nav>
      <main>{body'}</main>
    </body>
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
  Data.newTag f;
  Log.info ("<admin> created board /" ^ f.Nam ^ "/ - " ^ f.Slug);
  redirect (url (boards ()))


and delete_board { Nam = name } =
  Data.deleteTag name;
  Log.info ("<admin> deleted board /" ^ name ^ "/");
  redirect (url (boards ()))


and edit_slug f =
  Data.editSlug f;
  Log.info ("<admin> changed board /" ^ f.Nam ^ "/'s slug to " ^ f.Slug);
  redirect (url (boards ()))


and board name =
  t <- Data.catalogByTag' name;
  case t of None => error <xml>Board not found</xml> | Some threads =>
  layout <xml><table>
    <tr><th>ID</th><th>Subject</th></tr>
    {List.mapX (fn { Id = id, Subject = subject, ... } =>
      <xml><tr>
        <td>{[id]}</td><td>{[subject]}</td>
        <td><form>
          <hidden{#Id} value={show id}/>
          <hidden{#Tag} value={name}/>
          <submit value="Delete thread" onclick={confirmDel subject}
            action={delete_thread}/>
        </form></td>
      </tr></xml>)
      threads}
  </table></xml>


and delete_thread { Id = id, Tag = tag } =
  Data.deleteThread (readError id);
  Log.info ("<admin> deleted thread " ^ id);
  redirect (url (board tag))


and news_items () =
  n <- allNews;
  layout <xml><table>
    <tr><th>ID</th><th>Title</th><th>Author</th><th>Body</th></tr>
    {List.mapX (fn n => <xml>
        <tr>
          <td>{[n.Id]}</td><td>{[n.Title]}</td>
          <td>{[n.Author]}</td><td>{[n.Body]}</td>
          <td><a href={url (news_item n.Id)}>edit</a></td>
          <form>
            <hidden{#Id} value={show n.Id}/>
            <td><submit value="Delete item"
              onclick={confirmDel n.Title}
              action={delete_news_item}/></td>
          </form>
        </tr>
      </xml>) n}
  </table><form>
    <hidden{#Author} value="steenuil"/>
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
  id <- addNews x;
  Log.info ("<admin> added newsItem " ^ show id ^ ": " ^ x.Title);
  redirect (url (news_items ()))


and delete_news_item { Id = id } =
  deleteNews (readError id);
  Log.info ("<admin> deleted newsItem " ^ id);
  redirect (url (news_items ()))


and edit_news_item f =
  editNews (readError f.Id) (f -- #Id);
  Log.info ("<admin> edited newsItem " ^ f.Id);
  redirect (url (news_items ()))


and readme_text () =
  r <- readme;
  layout <xml>
    <div>{Post.toHtml' r.Body}</div>
    <form>
      <textarea{#Body} required placeholder="Readme">{[r.Body]}</textarea><br/>
      <submit value="Edit readme" action={edit_readme}/>
    </form>
  </xml>


and edit_readme { Body = body } =
  updateReadme body;
  Log.info "<admin> edited the readme";
  redirect (url (readme_text ()))
