datatype level = Debug | Info | Warning | Error

(* Convenience functor for logging,
 * so you can call Log.debug instead of log Logger.Debug and so on.
 * A module that needs to implement a logger should do it like this:
 * structure Log = Logger.Make(struct val section = "section name" end) *)
functor Make(M : sig val section : string end) : sig
  val log : level -> string -> transaction unit

  val debug   : string -> transaction unit
  val info    : string -> transaction unit
  val warning : string -> transaction unit
  val error   : string -> transaction unit
end
