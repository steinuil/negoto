type t

val create : int -> transaction t

val length : t -> transaction int

val contents : t -> transaction string

val addChar : t -> char -> transaction unit

val addString : t -> string -> transaction unit
