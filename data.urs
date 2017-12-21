type tag =
  { Nam  : string
  , Slug : string }
  (** A "board" imageboard terms. *)

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string }
  (** A thread which may belong to one or more tags. *)

type postFile =
  { Hash    : string
  , Nam     : string
  , Ext     : string
  , Spoiler : bool }
  (** A file included in a post. *)

type post =
  { Id     : int
  , Thread : int
  , Nam    : string
  , Time   : time
  , Body   : string
  , Files  : list postFile }
  (** A post belonging to a thread. *)

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
  (** A thread preview, which includes the thread info and its opening post. *)


val allTags : transaction (list tag)
  (** Return all the tags in the board. *)

val tagByName : string -> transaction (option tag)
  (** Search a tag by its name and return it. *)

val catalog : transaction (list catalogThread)
  (** Return previews for all threads. *)

val catalogByTag : string -> transaction (list catalogThread)
  (** Return previews for all threads associated with a certain tag. *)

val threadById : int -> transaction (option (thread * list post))
  (** Convenience function to get both thread info and posts for a thread ID. *)


val threadInfoById : int -> transaction (option thread)
  (** Return thread info for a single thread by its ID. *)

val postsByThread : int -> transaction (list post)
  (** Return all the posts of a thread by the thread ID. *)


(* Insert *)
val newTag : tag -> transaction unit

val newThread :
  { Nam  : string
  , Subject : string
  , Body : string
  , Files : list
    { File : file
    , Spoiler : bool }
  , Tags : list string } -> transaction unit

val newPost :
  { Nam : string
  , Body : string
  , Bump : bool
  , Files : list
    { File : file
    , Spoiler : bool }
  , Thread : int } -> transaction unit


(* Delete *)
val deleteFile : string -> transaction unit

val deleteTag : string -> transaction unit
