(* A buffer library inspired by OCaml's to make string concatenation less
 * painful for the Ur/Web runtime.
 * Buffers are append-only, and expand automatically as you add elements
 * to them. *)

type t

val create : int -> transaction t
  (* [create n] creates an empty buffer of [n] bytes. For best performance,
   * [n] should be about the same as the number of characters you expect to
   * store in it. *)

val contents : t -> transaction string
  (* Return a copy of the contents of the buffer as a string. *)

val length : t -> transaction int

val addChar : t -> char -> transaction unit

val addString : t -> string -> transaction unit
