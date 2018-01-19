val get : string -> transaction string

val getOpt : string -> transaction (option string)

val exists : string -> transaction bool

val set : string -> string -> transaction unit
