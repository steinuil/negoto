(* [KeyVal] provides a key-value interface to a SQL table.
 * Values are serialized as strings, but this module will work on any type that
 * implements [read] and [show] without explicitly converting the values to
 * strings.

 * Note that attempting to read a value with the incorrect type will
 * always raise an error. *)

val unsafeGet : a ::: Type -> read a -> string -> transaction a

val get : a ::: Type -> read a -> string -> transaction (option a)

val set : a ::: Type -> show a -> string -> a -> transaction unit

val exists : string -> transaction bool
