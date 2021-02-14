type board =
  { Id  : string
  , Nam : string }

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

val allBoards   : transaction (list board)
val nameOfBoard : string -> transaction (option string)

val addBoard      : board  -> transaction unit
val editBoardName : board  -> transaction unit
val deleteBoard   : string -> transaction unit

val wholeCatalog : transaction (list catalogThread)

val catalog  : string -> transaction (option (list catalogThread))
val catalog' : string -> transaction (list catalogThread)
  (** Like catalog, but just returns an empty list if the board doesn't exist. *)

val threadInfo : int -> transaction (option thread)

val addThread :
  { Nam     : string
  , Subject : string
  , Body    : string
  , Files   : list { Spoiler : bool, File : file }
  , Board   : string } -> transaction int

val toggleThreadLock : int -> transaction unit
val bumpThread       : int -> transaction unit
val deleteThread     : int -> transaction unit

val postsIn : int -> transaction (list post)
  (** Get all the posts in a thread. *)
val thread  : int -> transaction (option (thread * list post))
  (** Get a thread's info and all its posts. *)

val postsSince : int -> int -> transaction (list post)
  (** Get all posts in a thread given the last seen post number. *)

val recentPosts : int -> transaction (list { Number : int
                                           , Thread : int
                                           , Board : string
                                           , BoardName : string
                                           , Nam : string
                                           , Time : time
                                           , Body : string })

val addPost :
  { Nam    : string
  , Body   : string
  , Bump   : bool
  , Files  : list { Spoiler : bool, File : file }
  , Thread : int } -> transaction int

val deletePost : int -> transaction unit
  (** Delete a post given its Id. *)
val deletePostIn : int -> int -> transaction unit
  (** Delete a post given its thread and post number. *)

val deleteFile : File.handle -> transaction unit

val maxThreads : transaction int
val maxPosts   : transaction int
val setMaxThreads : int -> transaction unit
val setMaxPosts   : int -> transaction unit

val banIp : string -> int -> transaction unit
  (** Ban the selected IP for [n] seconds. *)
