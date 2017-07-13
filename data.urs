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


val allTags : transaction (list tag)

val tagByName : string -> transaction (option tag)

val newTag : tag -> transaction (option string)

val deleteTag : string -> transaction (option string)


val catalog : transaction (list catalogThread)

val catalogByTag : string -> transaction (list catalogThread)


val postsByThread : int -> transaction (list post)


val deleteFile : string -> transaction (option string)
