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

(* Files are stored by their hash, and be referenced by multiple posts.
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

fun newTag { Nam = name, Slug = slug } =
  if strlen name > 16
  then return (Some "name too long")
  else if strlen slug > 24
  then return (Some "slug too long")
  else tryDml (INSERT INTO tags (Nam, Slug)
              VALUES ({[name]}, {[slug]}))

(* TODO:
fun deleteTag
*)


(* * Thread functions *)
(* FIXME: collate threads and tags *)
fun unifyThread t tt =
  { Id = t.Id, Updated = t.Updated, Subject = t.Subject
  , Locked = t.Locked, Tag = tt.Tag }

fun allThreads () =
  query (SELECT * FROM threads
        JOIN thread_tags ON thread_tags.Thread = threads.Id)
        (fn { Threads = t, Thread_tags = tt } acc =>
          return (unifyThread t tt :: acc))
        []

fun threadsByTag name =
  query (SELECT * FROM threads
        JOIN thread_tags ON thread_tags.Thread = threads.Id
        WHERE thread_tags.Tag = {[name]})
        (fn { Threads = t, Thread_tags = tt } acc =>
          return (unifyThread t tt :: acc))
        []

(* TODO:
fun newThread
*)


(* * Post functions *)
(* FIXME: collate posts and files *)
fun allPosts () =
  query (SELECT posts.*, Post_files.Spoiler, files.* FROM posts
        LEFT OUTER JOIN post_files ON post_files.Post = posts.Key
        JOIN files ON {sql_nullable (SQL files.Hash)} = post_files.File
        ORDER BY posts.Id DESC)
        (fn { Posts = p, Post_files = pf, Files = f } acc => return (
          { Id = p.Id, Thread = p.Thread, Nam = p.Nam, Time = p.Time
          , Body = p.Body , Spoiler = pf.Spoiler, Hash = f.Hash
          , FileNam = f.Nam, Ext = f.Ext } :: acc))
        []


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
