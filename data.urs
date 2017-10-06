type tag =
  { Nam  : string
  , Slug : string }

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string }

type postFile =
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
  , Files  : list postFile }

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


(* Query *)
val allTags : transaction (list tag)

val tagByName : string -> transaction (option tag)

val catalog : transaction (list catalogThread)

val catalogByTag : string -> transaction (list catalogThread)

val threadById : int -> transaction (option thread)

val postsByThread : int -> transaction (list post)


(* Insert *)
val newTag : tag -> transaction Result.t

val newThread :
  { Nam  : string
  , Subject : string
  , Body : string
  , Files : list
    { File : file
    , Spoiler : bool }
  , Tags : list string } -> transaction Result.t

val newPost :
  { Nam : string
  , Body : string
  , Bump : bool
  , Files : list
    { File : file
    , Spoiler : bool }
  , Thread : int } -> transaction Result.t


(* Delete *)
val deleteFile : string -> transaction Result.t

val deleteTag : string -> transaction Result.t
