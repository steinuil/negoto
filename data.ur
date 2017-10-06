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

type file =
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
  , Files  : list file }

type catalogThread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string
  , Nam     : string
  , Time    : time
  , Body    : string
  , Files   : list file }


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

fun threadById id =
  thread <- query (SELECT * FROM threadView WHERE threadView.Id = {[id]})
    (return `compose2` coalesceThread')
    [];
  return (case thread of t :: _ => Some t | [] => None)


(* * Post *)
fun postsByThread id =
  query (SELECT * FROM postView WHERE postView.Thread = {[id]})
    (return `compose2` coalescePost')
    []


(* * File *)
val orphanedFiles =
  queryL1
    (SELECT files.* FROM files
     WHERE files.Post IS NULL)



(* * INSERT *)
fun newTag { Nam = name, Slug = slug } =
  Result.dml (INSERT INTO tags (Nam, Slug)
              VALUES ( {[name]}, {[slug]} ))

fun insertFile uid spoil file =
  random <- rand;
  Result.dml (INSERT INTO files (Hash, Nam, Ext, Spoiler, Post)
              VALUES ( {[show random]}, "file", "jpg"
                     , {[spoil]}, {[Some uid]} ))

fun newPost { Nam = name, Body = body, Spoiler = spoil
            , Sage = sage, Files = files', Thread = thread } =
  uid <- nextval thread_id;
  { Count = lastid } <- oneRow (SELECT COUNT( * ) AS Count FROM posts
                                WHERE posts.Thread = {[thread]});
  List.foldr (flip Result.mapM)
    (Result.dml (INSERT INTO posts (Uid, Id, Thread, Nam, Time, Body)
                 VALUES ( {[uid]}, {[lastid + 1]}, {[thread]}, {[name]}
                        , CURRENT_TIMESTAMP, {[body]} )))
    (List.mp (insertFile uid spoil) files')



(* * DELETE *)
fun deleteTag name =
  Result.dml (DELETE FROM tags WHERE Nam = {[name]})

(* FIXME: actually delete files *)
fun deleteFile hash =
  Result.dml (DELETE FROM files WHERE Hash = {[hash]})


(* * Tasks *)
(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
task periodic (30 * 60) = fn () =>
  files <- orphanedFiles;
  _ <- List.mapM (fn x => deleteFile x.Hash) files;
  Log.log "data" "checking for orphaned files"
