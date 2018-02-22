structure X : sig
type board =
  { Id  : string
  , Nam : string }

val allBoards   : transaction (list board)
val nameOfBoard : string -> transaction (option string)

val addBoard      : board  -> transaction unit
val editBoardName : board  -> transaction unit
val deleteBoard   : string -> transaction unit

type postFile =
  { Handle  : File.handle
  , Fname   : string
  , Src     : url
  , Thumb   : url
  , Spoiler : bool }

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

val wholeCatalog : transaction (list catalogThread)

val catalog  : string -> transaction (option (list catalogThread))
val catalog' : string -> transaction (list catalogThread)
end


(** Manage threads and boards and posts *)

type tag =
  { Nam  : string
  , Slug : string }
  (* A "board" imageboard terms. *)

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Count   : int
  , Locked  : bool
  , Tag     : string }
  (* A thread which may belong to one or more tags. *)

type postFile =
  { Hash    : string
  , Nam     : string
  , Mime    : string
  , Spoiler : bool }
  (* A file included in a post. *)

type post =
  { Id     : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string
  , Files  : list postFile }
  (* A post belonging to a thread. *)

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
  (* A thread preview, which includes the thread info and its opening post. *)


val allTags : transaction (list tag)
  (* Return all the tags in the board. *)

val tagByName : string -> transaction (option tag)
  (* Search a tag by its name and return it. *)

val catalog : transaction (list catalogThread)
  (* Return previews for all threads. *)

val catalogByTag : string -> transaction (list catalogThread)
  (* Return previews for all threads associated with a certain tag. *)

val catalogByTag' : string -> transaction (option (list catalogThread))
  (* Like catalogByTag, but returns None if the tag doesn't exist while
   * catalogByTag just returns an empty list. *)

val threadById : int -> transaction (option (thread * list post))
  (* Convenience function to get both thread info and posts for a thread ID. *)

val postsSince : int -> int -> transaction (list post)
  (* Get the new posts in a thread given the last seen ID. *)


val threadInfoById : int -> transaction (option thread)
  (* Return thread info for a single thread by its ID. *)

val postsByThread : int -> transaction (list post)
  (* Return all the posts of a thread by the thread ID. *)


(* Insert *)
val newTag : tag -> transaction unit

val newThread :
  { Nam  : string
  , Subject : string
  , Body : string
  , Files : list
    { File : file
    , Spoiler : bool }
  , Tag : string } -> transaction int

val newPost :
  { Nam : string
  , Body : string
  , Bump : bool
  , Files : list
    { File : file
    , Spoiler : bool }
  , Thread : int } -> transaction int


(* Edit *)
val editSlug : tag -> transaction unit

val lockThread : int -> transaction unit

val unlockThread : int -> transaction unit


(* Delete *)
val deleteTag : string -> transaction unit

val deleteFile : postFile -> transaction unit

val deleteFileByHash : string -> transaction unit

val deleteThread : int -> transaction unit

val deletePost : int -> int -> transaction unit
  (* [deletePost thread id] deletes a post given its thread ID and non-unique ID *)

val deletePostByUid : int -> transaction unit
  (* Delete a post given its unique ID. *)


val maxThreads : transaction int

val setMaxThreads : int -> transaction unit

val maxPosts : transaction int

val setMaxPosts : int -> transaction unit
