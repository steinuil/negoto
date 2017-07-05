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
 * while Id is the relative ID used when displaying the post. *)
(* TODO: should it be relative to the board or to the thread? *)
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

(* Files are stored by their hash, and can be referenced by multiple posts.
 * They should be deleted when every post referencing them is gone. *)
table files :
  { Hash : string
  , Nam  : string
  , Ext  : string }
  PRIMARY KEY (Hash)

table post_files :
  { Post    : int
  , File    : string
  , Spoiler : bool }
  CONSTRAINT Post FOREIGN KEY Post
    REFERENCES posts(Key)
    ON DELETE CASCADE,
  CONSTRAINT File FOREIGN KEY File
    REFERENCES files(Hash)
    ON DELETE CASCADE

(* TODO: admins *)
(* TODO: delete posts *)
(* TODO: users for bans *)




(* * Tag functions *)
fun allTags () =
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
fun coalesceThreads { Threads = t, Thread_tags = tt } acc =
  let
    val (tagList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if t.Id = hd.Id
      then (hd.Tags, rst)
      else ([], acc)
  in
    (t ++ { Tags = tt.Tag :: tagList }) :: rest
  end

fun queryThreads q =
  query q (return `Util.compose2` coalesceThreads) []

fun allThreads () =
  queryThreads
    (SELECT * FROM threads
    JOIN thread_tags
      ON thread_tags.Thread = threads.Id
    ORDER BY threads.Id DESC)

fun threadsByTag name =
  queryThreads
    (SELECT * FROM threads
    JOIN thread_tags
      ON thread_tags.Thread = threads.Id
    WHERE thread_tags.Tag = {[name]}
    ORDER BY threads.Id DESC)

(* TODO:
fun newThread
*)


(* * Post functions *)
fun coalescePosts { Posts = p, Post_files = pf, Files = f } acc =
  let
    val (fileList, rest) = case acc of
    | [] => ([], [])
    | hd :: rst =>
      if p.Id = hd.Id
      then (hd.Files, rst)
      else ([], hd :: rst)

    val files = case pf.Spoiler of
    | None => fileList
    | Some s => (f ++ { Spoiler = s }) :: fileList
  in
    (p -- #Key ++ { Files = files }) :: rest
  end

fun queryPosts q =
  query q (return `Util.compose2` coalescePosts) []

fun allPosts () =
  queryPosts
    (SELECT * FROM posts
    LEFT OUTER JOIN post_files
      ON post_files.Post = posts.Key
    JOIN files
      ON {sql_nullable (SQL files.Hash)} = post_files.File
    ORDER BY posts.Id DESC)

fun postsByThread threadId =
  queryPosts
    (SELECT * FROM posts
    LEFT OUTER JOIN post_files
      ON post_files.Post = posts.Key
    JOIN files
      ON {sql_nullable (SQL files.Hash)} = post_files.File
    WHERE posts.Thread = {[threadId]}
    ORDER BY posts.Id DESC)


(* * File functions *)
fun orphanedFiles () =
  queryL1
    (SELECT files.* FROM files
    JOIN post_files
      ON files.Hash <> post_files.File)



(* * Tasks *)
(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
(* FIXME: actually delete them *)
task periodic (30 * 60) = fn {} =>
  ls <- orphanedFiles ();
  if List.length ls < 1
  then Log.log "data" "no orphaned files found"
  else Log.log "data" ("orphaned files found: " ^
    Util.joinStrings ", " (List.mp (fn x => x.Nam) ls))
