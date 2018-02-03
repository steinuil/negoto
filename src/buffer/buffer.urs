type t

val create : int -> transaction t

val length : t -> int

val contents : t -> string

val addChar : t -> char -> transaction unit

val addString : t -> string -> transaction unit
