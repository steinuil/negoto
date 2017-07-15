(* * Tables *)
(* Negoto uses tags instead of boards.
 * A thread may belong to one or more tags. *)
table tags :
  { Nam  : string
  , Slug : string}
  PRIMARY KEY (Nam)

table threads :
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool }
  PRIMARY KEY (Id)

table thread_tags :
  { Thread : int
  , Tag    : string }
  CONSTRAINT Thread FOREIGN KEY Thread
    REFERENCES threads(Id)
    ON DELETE CASCADE,
  CONSTRAINT Tag FOREIGN KEY Tag
    REFERENCES tags(Nam)
    ON DELETE CASCADE

(* Key is the unique ID used to reference the post,
 * while Id is the ID (relative to the thread) used when displaying the post. *)
table posts :
  { Key    : int
  , Id     : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string }
  PRIMARY KEY (Key),
  CONSTRAINT Thread FOREIGN KEY Thread
    REFERENCES threads(Id)
    ON DELETE CASCADE

(* Ur/Web doesn't support database triggers, so we want to defer the deletion
 * of a row to the periodic task, so that we can call the function that
 * actually deletes the file. *)
table files :
  { Hash    : string
  , Nam     : string
  , Ext     : string
  , Spoiler : bool
  , Post    : option int }
  PRIMARY KEY (Hash),
  CONSTRAINT Post FOREIGN KEY Post
    REFERENCES posts(Key)
    ON DELETE SET NULL

(* TODO: admins *)
(* TODO: users for bans *)



(* * Tag functions *)
val allTags =
  queryL1 (SELECT * FROM tags)

fun tagByName name =
  oneOrNoRows1
    (SELECT * FROM tags
    WHERE tags.Nam = {[name]})

fun newTag { Nam = name, Slug = slug } =
  if strlen name > 16
  then return (Some "name too long")
  else if strlen slug > 24
  then return (Some "slug too long")
  else tryDml (INSERT INTO tags (Nam, Slug)
              VALUES ({[name]}, {[slug]}))

fun deleteTag name =
  tryDml
    (DELETE FROM tags
    WHERE Nam = {[name]})



(* * Thread functions *)
fun coalesceCatalogThread
  { Threads = t, Thread_tags = { Tag = tag, ... }, Posts = p, Files = f } acc =
let
  val (tagList, fileList, rest) = case acc of
    | [] => ([], [], [])
    | hd :: rst =>
      if t.Id = hd.Id
      then (hd.Tags, hd.Files, rst)
      else ([], [], acc)

  val post = { Nam = p.Nam, Time = p.Time, Body = p.Body }

  val fileList = case f of
    | { Hash = Some h, Nam = Some n, Ext = Some e, Spoiler = Some s, ... } =>
        if List.exists (fn x => x.Hash = h) fileList
        then fileList
        else { Hash = h, Nam = n, Ext = e, Spoiler = s } :: fileList
    | _ => fileList

  val tagList =
    if List.exists (fn x => x = tag) tagList
    then tagList
    else tag :: tagList
in
  (t ++ post ++ { Tags = tagList } ++ { Files = fileList }) :: rest
end

val catalog =
  query
    (SELECT * FROM threads
    JOIN thread_tags
      ON thread_tags.Thread = threads.Id
    JOIN posts
      ON posts.Thread = threads.Id
    LEFT OUTER JOIN files
      ON files.Post = {sql_nullable (SQL posts.Key)}
    WHERE posts.Id = 1
    ORDER BY threads.Updated, threads.Id DESC)
    (return `Util.compose2` coalesceCatalogThread)
    []

fun catalogByTag tag =
  query
    (SELECT * FROM threads
    JOIN thread_tags
      ON thread_tags.Thread = threads.Id
    JOIN posts
      ON posts.Thread = threads.Id
    LEFT OUTER JOIN files
      ON files.Post = {sql_nullable (SQL posts.Key)}
    WHERE posts.Id = 1
      AND thread_tags.Tag = {[tag]}
    ORDER BY threads.Updated, threads.Id DESC)
    (return `Util.compose2` coalesceCatalogThread)
    []


fun coalesceThread { Threads = t, Thread_tags = { Tag = tag, ... } } acc =
  let
    val (tagList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if t.Id = hd.Id
      then (hd.Tags, rst)
      else ([], acc)
  in
    (t ++ { Tags = tag :: tagList }) :: rest
end


fun threadById id =
  thread <- query
    (SELECT * FROM threads
    JOIN thread_tags
      ON thread_tags.Thread = threads.Id
    WHERE threads.Id = {[id]})
    (return `Util.compose2` coalesceThread)
    [];
  return (case thread of t :: _ => Some t | [] => None)



(* * Post functions *)
fun coalescePost { Posts = p, Files = f } acc = let
  val (fileList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if p.Id = hd.Id
      then (hd.Files, rst)
      else ([], acc)

  val fileList = case f of
    | { Hash = Some h, Nam = Some n, Ext = Some e, Spoiler = Some s, ... } =>
      { Hash = h, Nam = n, Ext = e, Spoiler = s } :: fileList
    | _ => fileList
in
  (p -- #Key ++ { Files = fileList }) :: rest
end

fun postsByThread threadId =
  query
    (SELECT * FROM posts
    LEFT OUTER JOIN files
      ON files.Post = {sql_nullable (SQL posts.Id)}
    WHERE posts.Thread = {[threadId]}
    ORDER BY posts.Id DESC)
    (return `Util.compose2` coalescePost)
    []



(* * File functions *)
val orphanedFiles =
  queryL1
    (SELECT files.* FROM files
    WHERE files.Post IS NULL)

(* FIXME: actually delete files *)
fun deleteFile hash =
  tryDml
    (DELETE FROM files
    WHERE Hash = {[hash]})



(* * Tasks *)
(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
(* FIXME: run deleteFile *)
task periodic (30 * 60) = fn () =>
  files <- orphanedFiles;
  (* _ <- Monad.appR deleteFile files; *)
  Log.log "data" "checking for orphaned files"
