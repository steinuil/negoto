structure Log = Logger.Make(struct val section = "admin" end)


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


fun addNews { Title = title, Author = author, Body = body } =
  id <- nextval newsItems_id;
  dml (INSERT INTO newsItems (Id, Title, Author, Time, Body)
       VALUES ( {[id]}, {[title]}, {[author]}, CURRENT_TIMESTAMP, {[body]} ));
  return id


fun deleteNews (id : int) =
  dml (DELETE FROM newsItems WHERE Id = {[id]})



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
      <xml><tr><td>{[id]}</td><td>{[subject]}</td></tr></xml>)
      threads}
  </table></xml>


and news_items () =
  n <- allNews;
  layout <xml><table>
    <tr><th>ID</th><th>Title</th><th>Author</th><th>Body</th></tr>
    {List.mapX (fn n => <xml>
        <tr>
          <td>{[n.Id]}</td><td>{[n.Title]}</td>
          <td>{[n.Author]}</td><td>{[n.Body]}</td>
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


and create_news_item x =
  id <- addNews x;
  Log.info ("<admin> added newsItem " ^ show id ^ ": " ^ x.Title);
  redirect (url (news_items ()))


and delete_news_item { Id = id } =
  deleteNews (readError id);
  Log.info ("<admin> deleted newsItem " ^ id);
  redirect (url (news_items ()))
