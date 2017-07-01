(* * TABLES *)
(* Negoto uses tags instead of boards.
 * A thread may belong to one or more tags. *)
table tags :
  { Nam : string
  , Id  : int }
  PRIMARY KEY (Id)

table threads :
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool }
  PRIMARY KEY (Id)

table thread_tags :
  { Thread : int
  , Tag    : int }
  CONSTRAINT Thread FOREIGN KEY Thread
    REFERENCES threads(Id)
    ON DELETE CASCADE,
  CONSTRAINT Tag FOREIGN KEY Tag
    REFERENCES tags(Id)
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



(* Periodically check for orphaned files
 * and delete them from the database/filesystem *)
(* TODO: actually delete them *)
task periodic (30 * 60) = fn {} =>
  r <- hasRows
    (SELECT files.Hash FROM files
    JOIN post_files
    ON files.Hash <> post_files.File);
  if r
  then Log.log "data" "found orphaned files"
  else Log.log "data" "no orphaned files found"
