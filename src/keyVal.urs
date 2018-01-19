val get : string -> transaction string

val safeGet : string -> string -> transaction string
  (* [safeGet key default] like [get], but returns [default] when
   * the key is not found. *)

val exists : string -> transaction bool

val set : string -> string -> transaction unit
