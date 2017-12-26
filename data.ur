open Util

(* Output types *)
type tag =
  { Nam  : string
  , Slug : string }

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string }

type postFile =
  { Hash    : string
  , Nam     : string
  , Ext     : string
  , Spoiler : bool }

type post =
  { Id     : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string
  , Files  : list postFile }

type catalogThread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string
  , Nam     : string
  , Time    : time
  , Body    : string
  , Files   : list postFile }


(* * Tables *)
sequence thread_id
sequence post_id

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

(* Uid is the unique ID used to reference the post,
 * while Id is the ID (relative to the thread) used when displaying the post. *)
table posts :
  { Uid    : int
  , Id     : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string }
  PRIMARY KEY (Uid),
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
    REFERENCES posts(Uid)
    ON DELETE SET NULL

(* TODO: admins *)
(* TODO: users for bans *)



(* * Views *)
view catalogView =
  SELECT threads.Id   AS Id
    , threads.Updated AS Updated
    , threads.Subject AS Subject
    , threads.Locked  AS Locked
    , thread_tags.Tag AS Tag
    , posts.Nam       AS Nam
    , posts.Time      AS Time
    , posts.Body      AS Body
    , files.Hash      AS Hash
    , files.Nam       AS Filename
    , files.Ext       AS Ext
    , files.Spoiler   AS Spoiler
  FROM threads
  JOIN thread_tags
    ON thread_tags.Thread = threads.Id
  JOIN posts
    ON posts.Thread = threads.Id
  LEFT OUTER JOIN files
    ON files.Post = {sql_nullable (SQL posts.Uid)}
  WHERE posts.Id = 1
  ORDER BY threads.Updated, threads.Id DESC

view threadView =
  SELECT threads.Id   AS Id
    , threads.Updated AS Updated
    , threads.Subject AS Subject
    , threads.Locked  AS Locked
    , thread_tags.Tag AS Tag
  FROM threads
  JOIN thread_tags
    ON thread_tags.Thread = threads.Id

view postView =
  SELECT posts.Id   AS Id
    , posts.Thread  AS Thread
    , posts.Nam     AS Nam
    , posts.Time    AS Time
    , posts.Body    AS Body
    , files.Hash    AS Hash
    , files.Nam     AS Filename
    , files.Ext     AS Ext
    , files.Spoiler AS Spoiler
  FROM posts
  LEFT OUTER JOIN files
    ON files.Post = {sql_nullable (SQL posts.Uid)}
  ORDER BY posts.Id DESC



(* * Coalesce functions *)
(* TODO: generic coalesce function that takes field names *)
fun coalesceCatalogThread { CatalogView = c } acc = let
  val (tagList, fileList, rest) = case acc of
    | [] => ([], [], [])
    | hd :: rst =>
      if c.Id = hd.Id
      then (hd.Tags, hd.Files, rst)
      else ([], [], acc)

  val thread = c -- #Tag -- #Hash -- #Filename -- #Ext -- #Spoiler

  val fileList = case (c.Hash, c.Filename, c.Ext, c.Spoiler) of
    | (Some h, Some n, Some e, Some s) =>
      if List.exists (fn x => x.Hash = h) fileList
      then fileList
      else { Hash = h, Nam = n, Ext = e, Spoiler = s } :: fileList
    | _ => fileList

  val tagList =
    if List.exists (fn x => x = c.Tag) tagList
    then tagList
    else c.Tag :: tagList
in
  (thread ++ { Tags = tagList } ++ { Files = fileList }) :: rest
end

fun coalesceThread' { ThreadView = t } acc = let
  val thread = t -- #Tag

  val (tagList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if t.Id = hd.Id
      then (hd.Tags, rst)
      else ([], acc)
in
  (thread ++ { Tags = t.Tag :: tagList }) :: rest
end


fun coalescePost' { PostView = p } acc = let
  val (fileList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if p.Id = hd.Id
      then (hd.Files, rst)
      else ([], acc)

  val fileList = case (p.Hash, p.Filename, p.Ext, p.Spoiler) of
    | (Some h, Some n, Some e, Some s) =>
      { Hash = h, Nam = n, Ext = e, Spoiler = s } :: fileList
    | _ => fileList

  val post = p -- #Hash -- #Filename -- #Ext -- #Spoiler
in
  (post ++ { Files = fileList }) :: rest
end




(* * QUERY *)
(* * Tag *)
val allTags =
  queryL1 (SELECT * FROM tags)

fun tagByName name =
  oneOrNoRows1
    (SELECT * FROM tags
     WHERE tags.Nam = {[name]})


(* * Thread *)
val catalog =
  query (SELECT * FROM catalogView)
    (return `compose2` coalesceCatalogThread)
    []

val catalogByTag tag =
  query (SELECT * FROM catalogView
        WHERE catalogView.Tag = {[tag]})
    (return `compose2` coalesceCatalogThread)
    []

fun threadInfoById id =
  thread <- query (SELECT * FROM threadView WHERE threadView.Id = {[id]})
    (return `compose2` coalesceThread')
    [];
  return (case thread of t :: _ => Some t | [] => None)


(* * Post *)
fun postsByThread id =
  query (SELECT * FROM postView WHERE postView.Thread = {[id]})
    (return `compose2` coalescePost')
    []

fun threadById id =
  thread' <- threadInfoById id;
  case thread' of
  | None => return None
  | Some t =>
    posts <- postsByThread id;
    return (Some (t, posts))


(* * File *)
val orphanedFiles =
  queryL1
    (SELECT files.* FROM files
     WHERE files.Post IS NULL)



(* * INSERT *)
fun newTag { Nam = name, Slug = slug } =
  dml (INSERT INTO tags (Nam, Slug)
       VALUES ( {[name]}, {[slug]} ))

fun insertFile uid ({ Spoiler = spoiler, File = file } : {Spoiler:bool,File:file}) =
  hash <- rand;
  File.save (show hash) file;
  dml (INSERT INTO files (Hash, Nam, Ext, Spoiler, Post)
       VALUES ( {[show hash]}, "file", "jpg"
              , {[spoiler]}, {[Some uid]} ))

fun insertThreadTag thread tag =
  dml (INSERT INTO thread_tags (Thread, Tag)
       VALUES ( {[thread]}, {[tag]} ))

fun bumpThread id shouldBump =
  if shouldBump then
    tim <- now;
    dml (UPDATE threads SET Updated = {[tim]}
         WHERE Id = {[id]})
  else return ()

fun newPost { Nam = name, Body = body, Bump = shouldBump
            , Files = files', Thread = thread } =
  uid <- nextval post_id;
  { Count = lastid } <- oneRow (SELECT COUNT( * ) AS Count FROM posts
                                WHERE posts.Thread = {[thread]});
  bumpThread thread shouldBump;
  dml (INSERT INTO posts (Uid, Id, Thread, Nam, Time, Body)
       VALUES ( {[uid]}, {[lastid + 1]}, {[thread]}, {[name]}
              , CURRENT_TIMESTAMP, {[body]} ));
  List.app (insertFile uid) files';
  return uid


fun newThread { Nam = name, Subject = subj, Body = body
              , Files = files', Tags = tags } =
  id <- nextval thread_id;
  dml (INSERT INTO threads (Id, Updated, Subject, Locked)
       VALUES ( {[id]}, CURRENT_TIMESTAMP, {[subj]}, {[False]} ));
  List.app (insertThreadTag id) tags;
  _ <- newPost { Nam = name, Body = body, Bump = True, Files = files', Thread = id };
  return id



(* * DELETE *)
fun deleteTag name =
  dml (DELETE FROM tags WHERE Nam = {[name]})

fun deleteFile { Hash = hash, Ext = ext, ... } =
  File.delete hash;
  dml (DELETE FROM files WHERE Hash = {[hash]})

fun deleteThread id =
  dml (DELETE FROM threads WHERE Id = {[id]})

fun deletePost thread id =
  dml (DELETE FROM posts WHERE Thread = {[thread]} AND Id = {[id]})

fun deletePostByUid uid =
  dml (DELETE FROM posts WHERE Uid = {[uid]})


(* * Tasks *)
(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
task periodic (30 * 60) = fn () =>
  files <- orphanedFiles;
  List.app (fn f => deleteFile (f -- #Post))  files;
  Log.log "data" "checking for orphaned files"
