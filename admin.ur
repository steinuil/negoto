structure Log = Logger.Make(struct val section = "admin" end)


table newsItems :
  { Title   : string
  , Author  : string
  , Time    : time
  , Body    : string }


val news =
  queryL1 (SELECT * FROM newsItems ORDER BY newsItems.Time ASC)
  (* The order is inverted because queryL1 returns stuff like that *)


table admins :
  { Nam : string }


fun layout (body' : xbody) : transaction page =
  return <xml>
    <head>
      <title>Admin</title>
    </head>
    <body>{body'}</body>
  </xml>


fun boards () =
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
            <td><submit value="Edit slug" action={editSlug}/></td>
          </form>
          <td><form><hidden{#Nam} value={name}/>
            <submit value="Delete board" action={deleteBoard}
              onclick={fn ev =>
                shouldDelete <- confirm ("Do you really want to delete /" ^ name ^ "/?");
                if shouldDelete then
                  return ()
                else
                  preventDefault}/>
          </form></td>
        </tr></xml>)
        tags}
      <form>
        <tr>
          <td><textbox{#Nam} required placeholder="Name"/></td>
          <td><textbox{#Slug} required placeholder="Slug"/></td>
          <td><submit value="Add boards" action={boardFormHandler}/></td>
        </tr>
      </form>
    </table>
  </xml>


(* TODO: validation *)
and boardFormHandler f =
  Data.newTag f;
  Log.info ("<admin> created /" ^ f.Nam ^ "/ - " ^ f.Slug);
  redirect (url (boards ()))


and deleteBoard { Nam = name } =
  Data.deleteTag name;
  Log.info ("<admin> deleted /" ^ name ^ "/");
  redirect (url (boards ()))


and editSlug f =
  Data.editSlug f;
  Log.info ("<admin> changed /" ^ f.Nam ^ "/'s slug to " ^ f.Slug);
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
