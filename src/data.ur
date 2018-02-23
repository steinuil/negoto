open Util

structure Log = Logger.Make(struct val section = "data" end)


structure X = struct
(* Manage boards *)
table boards :
  { Id  : string
  , Nam : string}
  PRIMARY KEY (Id)


type board =
  { Id  : string
  , Nam : string }


val allBoards =
  queryL1 (SELECT * FROM boards)


fun nameOfBoard id =
  oneColOpt [#Nam] (SELECT boards.Nam FROM boards WHERE boards.Id = {[id]})


fun addBoard { Id = id, Nam = name } =
  dml (INSERT INTO boards (Id, Nam)
       VALUES ({[id]}, {[name]}))


fun deleteBoard id =
  dml (DELETE FROM boards WHERE Id = {[id]})


fun editBoardName { Id = id, Nam = newName } =
  dml (UPDATE boards SET Nam = {[newName]} WHERE Id = {[id]})


table threads :
  { Id      : int
  , Board   : string
  , Updated : time
  , Subject : string
  , Count   : int
  , Locked  : bool }
  PRIMARY KEY (Id),
  CONSTRAINT Board FOREIGN KEY Board
    REFERENCES boards(Id)
    ON DELETE CASCADE


table posts :
  { Id     : int
  , Number : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string }
  PRIMARY KEY (Id)
  CONSTRAINT Thread FOREIGN KEY Thread
    REFERENCES threads(Id)
    ON DELETE CASCADE


table files :
  { Handle  : File.handle
  , Fname   : string
  , Src     : url
  , Thumb   : url
  , Spoiler : bool
  , Post    : option int }
  PRIMARY KEY (Handle),
  CONSTRAINT Post FOREIGN KEY Post
    REFERENCES posts(Id)
    ON DELETE SET NULL


type postFile =
  { Handle  : File.handle
  , Fname   : string
  , Src     : url
  , Thumb   : url
  , Spoiler : bool }


type thread =
  { Id      : int
  , Board   : string
  , Updated : time
  , Subject : string
  , Count   : int
  , Locked  : bool }


type catalogThread =
  { Id      : int
  , Board   : string
  , Updated : time
  , Subject : string
  , Count   : int
  , Locked  : bool
  , Nam     : string
  , Time    : time
  , Body    : string
  , Files   : list postFile }

type post =
  { Id     : int
  , Number : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string
  , Files  : list postFile }


(* Maximum threads per board *)
val maxThreads : transaction int =
  Util.getM 30 (KeyVal.get "maxThreads")


val setMaxThreads (i : int) =
  KeyVal.set "maxThreads" i


(* Maximum posts per thread *)
val maxPosts : transaction int =
  Util.getM 1000 (KeyVal.get "maxPosts")


val setMaxPosts (i : int) =
  KeyVal.set "maxPosts" i


(* IDs *)
sequence thread_id
sequence post_id


(* Threads and catalog *)
fun queryCatalog expr =
  query (SELECT * FROM threads
         JOIN posts ON posts.Thread = threads.Id
         LEFT OUTER JOIN files ON files.Post = {sql_nullable (SQL posts.Id)}
         WHERE posts.Number = 1 AND {expr}
         ORDER BY threads.Updated, threads.Id DESC)
    (fn { Threads = t, Posts = p, Files = f } acc =>
      let
        return (thread :: acc)
      where
        val file = record_seqOpt (f -- #Post)

        val (acc, thread) = case acc of
          | hd :: rest =>
            if hd.Id = t.Id then
              (rest, hd -- #Files ++
                { Files = case file of Some f => f :: hd.Files | None => hd.Files })
            else
              (acc, t ++ (p -- #Id -- #Thread -- #Number) ++
                { Files = case file of Some f => f :: [] | None => [] })
          | [] =>
              (acc, t ++ (p -- #Id -- #Thread -- #Number) ++
                { Files = case file of Some f => f :: [] | None => [] })
      end)
    []


val wholeCatalog =
  queryCatalog (WHERE TRUE)


fun catalog' board =
  queryCatalog (WHERE threads.Board = {[board]})


fun catalog board =
  exists <- hasRows (SELECT 1 FROM boards WHERE boards.Id = {[board]});
  if exists then
    c <- catalog' board;
    return (Some c)
  else
    return None

fun threadInfo id =
  oneOrNoRows1 (SELECT * FROM threads WHERE threads.Id = {[id]})


fun toggleThreadLock id =
  dml (UPDATE threads SET Locked = NOT t.Locked WHERE Id = {[id]})


fun bumpThread id =
  dml (UPDATE threads SET Updated = CURRENT_TIMESTAMP WHERE Id = {[id]})


fun deleteThread id =
  dml (DELETE FROM threads WHERE Id = {[id]})


fun deleteOldThreads board =
  max <- maxThreads;
  { Count = count } <- oneRow (SELECT COUNT( * ) AS Count FROM threads
                               WHERE threads.Board = {[board]});
  if count > max then
    overflow <- query (SELECT threads.Id AS Id FROM threads
                       ORDER BY threads.Updated ASC LIMIT {max - count + 1})
                  (fn { Id = id } acc => return (id :: acc)) [];
    let fun many (ls : list int) acc = case ls of
      | []      => acc
      | x :: xs => many xs (WHERE t.Id = {[x]} OR {acc})
    in
      dml (DELETE FROM threads WHERE {many overflow (WHERE FALSE)})
    end
  else
    return ()


(* Posts *)
fun queryPost expr =
  query (SELECT * FROM posts
         LEFT OUTER JOIN files ON files.Post = {sql_nullable (SQL posts.Id)}
         WHERE {expr}
         ORDER BY posts.Id DESC)
    (fn { Posts = p, Files = f } acc =>
      let
        return (thread :: acc)
      where
        val file = record_seqOpt (f -- #Post)

        val (acc, thread) = case acc of
          | hd :: rest =>
            if hd.Id = p.Id then
              (rest, hd -- #Files ++
                { Files = case file of Some f => f :: hd.Files | None => hd.Files })
            else
              (acc, p ++ { Files = case file of Some f => f :: [] | None => [] })
          | [] =>
              (acc, p ++ { Files = case file of Some f => f :: [] | None => [] })
      end)
    []


fun postsIn thread =
  queryPost (WHERE posts.Thread = {[thread]})


fun thread thread =
  info <- threadInfo thread;
  case info of
  | None => return None
  | Some info =>
    posts <- postsIn thread;
    return (Some (info, posts))


fun postsSince thread lastNum =
  queryPost (WHERE posts.Thread = {[thread]} AND posts.Number > {[lastNum]})


fun deletePostIn thread num =
  if num > 1 then
    dml (DELETE FROM posts WHERE Thread = {[thread]} AND Number = {[num]})
  else
    deleteThread thread


fun deletePost id =
  { Number = num, Thread = thread } <- oneRow1 (SELECT posts.Number, posts.Thread
                                                FROM posts WHERE posts.Id = {[id]});
  if num > 1 then
    dml (DELETE FROM posts WHERE Id = {[id]})
  else
    deleteThread thread


fun deleteFile handle =
  dml (DELETE FROM files WHERE Handle = {[handle]});
  File.Image.delete handle



fun insertFile post { Spoiler = spoiler, File = file } =
  (handle, { Src = src, Thumb = thumb }) <- File.Image.save file;
  let val fname = fileName file |> Option.get "<unnamed>" in
    dml (INSERT INTO files (Handle, Fname, Src, Thumb, Spoiler, Post) VALUES
         ({[handle]}, {[fname]}, {[src]}, {[thumb]}, {[spoiler]}, {[Some post]}))
  end


fun addPost { Nam = name, Body = body, Bump = shouldBump
            , Files = files, Thread = thread } =
  { Count = count, Locked = locked } <-
    oneRow1 (SELECT threads.Count, threads.Locked FROM threads
             WHERE threads.Id = {[thread]});
  if locked then error <xml>This thread is locked</xml> else
  postLimit <- maxPosts;
  if count >= postLimit then error <xml>Post limit exceeded</xml> else
  id <- nextval post_id;
  dml (INSERT INTO posts (Id, Number, Thread, Nam, Time, Body) VALUES
       ({[id]}, {[count + 1]}, {[thread]}, {[name]}, CURRENT_TIMESTAMP, {[body]}));
  List.app (insertFile id) files;
  if shouldBump then
    dml (UPDATE threads SET Count = {[count + 1]}, Updated = CURRENT_TIMESTAMP
         WHERE Id = {[thread]});
    return id
  else
    dml (UPDATE threads SET Count = {[count + 1]} WHERE Id = {[thread]});
    return id


fun addThread { Nam = name, Subject = subject, Body = body, Files = files, Board = board } =
  deleteOldThreads board;
  id <- nextval thread_id;
  dml (INSERT INTO threads (Id, Board, Updated, Subject, Count, Locked) VALUES
       ({[id]}, {[board]}, CURRENT_TIMESTAMP, {[subject]}, 1, FALSE));
  postId <- nextval post_id;
  dml (INSERT INTO posts (Id, Number, Thread, Nam, Time, Body) VALUES
       ({[postId]}, 1, {[id]}, {[name]}, CURRENT_TIMESTAMP, {[body]}));
  List.app (insertFile postId) files;
  return id


(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
task periodic (30 * 60) = fn () =>
  Log.info "checking for orphaned files";
  files <- oneCols [#Handle] (SELECT files.Handle FROM files WHERE files.Post IS NULL);
  List.app deleteFile files
end


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


val maxPosts : transaction int =
  Util.getM 1000 (KeyVal.get "maxPosts")


val setMaxPosts (i : int) =
  KeyVal.set "maxPosts" i


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
  postLim <- maxPosts;
  if lastCnt >= postLim then error <xml>Post limit exceeded</xml> else
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



(* DELETE *)
fun deleteTag name =
  dml (DELETE FROM tags WHERE Nam = {[name]})

fun deleteFile { Hash = hash, Mime = mime, ... } =
  File.deleteImage hash mime;
  dml (DELETE FROM files WHERE Hash = {[hash]})

fun deleteFileByHash hash =
  { Mime = mime } <- oneRow1 (SELECT files.Mime FROM files
                              WHERE files.Hash = {[hash]});
  File.deleteImage hash mime;
  dml (DELETE FROM files WHERE Hash = {[hash]})

fun deleteThread id =
  dml (DELETE FROM threads WHERE Id = {[id]})

fun deletePost thread id =
  if id > 1 then
    dml (DELETE FROM posts WHERE Thread = {[thread]} AND Id = {[id]})
  else
    deleteThread thread

fun deletePostByUid uid =
  { Id = id, Thread = thread } <-
    oneRow1 (SELECT posts.Id, posts.Thread FROM posts WHERE posts.Uid = {[uid]});
  if id > 1 then
    dml (DELETE FROM posts WHERE Uid = {[uid]})
  else
    deleteThread thread
