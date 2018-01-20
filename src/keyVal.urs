val unsafeGet : string -> transaction string

val get : string -> transaction (option string)

val exists : string -> transaction bool

val set : string -> string -> transaction unit
