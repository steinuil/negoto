type t

val create : int -> transaction t

val length : t -> int

val contents : t -> string

val addString : t -> string -> transaction unit
