open Util

structure Log = Logger.Make(struct val section = "data" end)


(* Output types *)
type tag =
  { Nam  : string
  , Slug : string }

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Count   : int
  , Locked  : bool
  , Tag     : string }

type postFile =
  { Hash    : string
  , Nam     : string
  , Mime    : string
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
  , Count   : int
  , Locked  : bool
  , Tag     : string
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
  , Count   : int
  , Locked  : bool
  , Tag     : string }
  PRIMARY KEY (Id),
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
  , Mime    : string
  , Spoiler : bool
  , Post    : option int }
  PRIMARY KEY (Hash),
  CONSTRAINT Post FOREIGN KEY Post
    REFERENCES posts(Uid)
    ON DELETE SET NULL




(* * Views *)
view catalogView =
  SELECT threads.Id   AS Id
    , threads.Updated AS Updated
    , threads.Subject AS Subject
    , threads.Locked  AS Locked
    , threads.Count   AS Count
    , threads.Tag     AS Tag
    , posts.Nam       AS Nam
    , posts.Time      AS Time
    , posts.Body      AS Body
    , files.Hash      AS Hash
    , files.Nam       AS Filename
    , files.Mime      AS Mime
    , files.Spoiler   AS Spoiler
  FROM threads
  JOIN posts
    ON posts.Thread = threads.Id
  LEFT OUTER JOIN files
    ON files.Post = {sql_nullable (SQL posts.Uid)}
  WHERE posts.Id = 1
  ORDER BY threads.Updated, threads.Id DESC

view postView =
  SELECT posts.Id   AS Id
    , posts.Thread  AS Thread
    , posts.Nam     AS Nam
    , posts.Time    AS Time
    , posts.Body    AS Body
    , files.Hash    AS Hash
    , files.Nam     AS Filename
    , files.Mime    AS Mime
    , files.Spoiler AS Spoiler
  FROM posts
  LEFT OUTER JOIN files
    ON files.Post = {sql_nullable (SQL posts.Uid)}
  ORDER BY posts.Id DESC



(* * Coalesce functions *)
(* TODO: generic coalesce function that takes field names *)
fun coalesceCatalogThread { CatalogView = c } acc = let
  val (fileList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if c.Id = hd.Id
      then (hd.Files, rst)
      else ([], acc)

  val thread = c -- #Hash -- #Filename -- #Mime -- #Spoiler

  val fileList = case (c.Hash, c.Filename, c.Mime, c.Spoiler) of
    | (Some h, Some n, Some e, Some s) =>
      if List.exists (fn x => x.Hash = h) fileList
      then fileList
      else { Hash = h, Nam = n, Mime = e, Spoiler = s } :: fileList
    | _ => fileList
in
  (thread ++ { Files = fileList }) :: rest
end


fun coalescePost' { PostView = p } acc = let
  val (fileList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if p.Id = hd.Id
      then (hd.Files, rst)
      else ([], acc)

  val fileList = case (p.Hash, p.Filename, p.Mime, p.Spoiler) of
    | (Some h, Some n, Some e, Some s) =>
      { Hash = h, Nam = n, Mime = e, Spoiler = s } :: fileList
    | _ => fileList

  val post = p -- #Hash -- #Filename -- #Mime -- #Spoiler
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

fun catalogByTag' tag =
  t <- tagByName tag;
  case t of
  | None => return None
  | Some _ =>
    x <- catalogByTag tag;
    return (Some x)

fun threadInfoById id =
  oneOrNoRows1 (SELECT * FROM threads WHERE threads.Id = {[id]})


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

fun postsSince thread lastId =
  query (SELECT * FROM postView
         WHERE postView.Thread = {[thread]} AND postView.Id > {[lastId]})
    (return `compose2` coalescePost')
    []


(* * File *)
val orphanedFiles =
  queryL1
    (SELECT files.* FROM files
     WHERE files.Post IS NULL)


(* Max threads per tag *)
val maxThreads : transaction int =
  Util.getM 30 (KeyVal.get "maxThreads")


val setMaxThreads (i : int) =
  KeyVal.set "maxThreads" i


(* * INSERT *)
fun newTag { Nam = name, Slug = slug } =
  dml (INSERT INTO tags (Nam, Slug)
       VALUES ( {[name]}, {[slug]} ))

fun insertFile uid { Spoiler = spoiler, File = file } =
  hash <- File.saveImage file;
  dml (INSERT INTO files (Hash, Nam, Mime, Spoiler, Post)
       VALUES ( {[hash]}, {[Option.get "<unnamed>" (fileName file)]}
              , {[fileMimeType file]} , {[spoiler]}, {[Some uid]} ))

fun bumpThread id shouldBump =
  if shouldBump then
    tim <- now;
    dml (UPDATE threads SET Updated = {[tim]}
         WHERE Id = {[id]})
  else return ()

fun newPost { Nam = name, Body = body, Bump = shouldBump
            , Files = files', Thread = thread } =
  { Count = lastCnt, Locked = locked } <-
    oneRow1 (SELECT threads.Count, threads.Locked FROM threads
             WHERE threads.Id = {[thread]});
  if lastCnt >= 1000 then error <xml>Post limit exceeded</xml> else
  if locked then error <xml>This thread is locked</xml> else
  uid <- nextval post_id;
  bumpThread thread shouldBump;
  dml (INSERT INTO posts (Uid, Id, Thread, Nam, Time, Body)
       VALUES ( {[uid]}, {[lastCnt + 1]}, {[thread]}, {[name]}
              , CURRENT_TIMESTAMP, {[body]} ));
  dml (UPDATE threads SET Count = {[lastCnt + 1]}
       WHERE Id = {[thread]});
  List.app (insertFile uid) files';
  return uid

fun deleteOldThreads tag =
  max <- maxThreads;
  { Count = cnt } <- oneRow (SELECT COUNT( * ) AS Count FROM threads
                             WHERE threads.Tag = {[tag]});
  if cnt >= max then
    overflow <- query (SELECT threads.Id AS Id FROM threads
                       ORDER BY threads.Updated ASC LIMIT {max - cnt + 1})
                  (fn { Id = id } acc => return (id :: acc)) [];
    let fun many (ls : list int) = case ls of
      | []       => (WHERE FALSE)
      | x :: []  => (WHERE t.Id = {[x]})
      | x :: rst => (WHERE t.Id = {[x]} OR {many rst})
    in
      dml (DELETE FROM threads WHERE {many overflow})
    end
  else
    return ()

fun newThread { Nam = name, Subject = subj, Body = body
              , Files = files', Tag = tag } =
  deleteOldThreads tag;
  id <- nextval thread_id;
  dml (INSERT INTO threads (Id, Updated, Subject, Count, Locked, Tag)
       VALUES ( {[id]}, CURRENT_TIMESTAMP, {[subj]}, 0, {[False]}, {[tag]} ));
  _ <- newPost { Nam = name, Body = body, Bump = True, Files = files', Thread = id };
  return id



(* EDIT *)
fun editSlug { Nam = name, Slug = slug } =
  dml (UPDATE tags SET Slug = {[slug]}
       WHERE Nam = {[name]})

fun lockThread id =
  dml (UPDATE threads SET Locked = {[True]} WHERE Id = {[id]})

fun unlockThread id =
  dml (UPDATE threads SET Locked = {[False]} WHERE Id = {[id]})



(* * DELETE *)
fun deleteTag name =
  dml (DELETE FROM tags WHERE Nam = {[name]})

fun deleteFile { Hash = hash, Mime = mime, ... } =
  File.deleteImage hash mime;
  dml (DELETE FROM files WHERE Hash = {[hash]})

fun deleteThread id =
  dml (DELETE FROM threads WHERE Id = {[id]})

fun deletePost thread id =
  if id > 1 then
    dml (DELETE FROM posts WHERE Thread = {[thread]} AND Id = {[id]})
  else
    deleteThread id

fun deletePostByUid uid =
  dml (DELETE FROM posts WHERE Uid = {[uid]})


(* * Tasks *)
(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
task periodic (30 * 60) = fn () =>
  files <- orphanedFiles;
  List.app (fn f => deleteFile (f -- #Post)) files;
  Log.info "checking for orphaned files"
