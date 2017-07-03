type tag =
  { Nam  : string
  , Slug : string }

type thread =
  { Id      : int
  , Updated : time
  , Subject : string
  , Locked  : bool
  , Tag     : string } (* : list string } *)

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


val allTags : unit -> transaction (list tag)

val newTag : tag -> transaction (option string)


val allThreads : unit -> transaction (list thread)

val threadsByTag : string -> transaction (list thread)
