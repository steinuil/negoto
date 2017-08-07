type tag =
  { Nam  : string
  , Slug : string }

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string }

type file =
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
  , Files  : list file }

type catalogThread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tags    : list string
  , Nam     : string
  , Time    : time
  , Body    : string
  , Files   : list file }


(* Query *)
val allTags : transaction (list tag)

val tagByName : string -> transaction (option tag)

val catalog : transaction (list catalogThread)

val catalogByTag : string -> transaction (list catalogThread)

val threadById : int -> transaction (option thread)

val postsByThread : int -> transaction (list post)


(* Insert *)
val newTag : tag -> transaction Util.result

val newPost :
  { Nam : string
  , Body : string
  , Spoiler : bool
  , Sage : bool
  , Files : list string
  , Thread : int } -> transaction Util.result


(* Delete *)
val deleteFile : string -> transaction Util.result

val deleteTag : string -> transaction Util.result
