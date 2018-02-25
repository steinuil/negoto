open Util

structure Log = Logger.Make(struct val section = "data" end)


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
