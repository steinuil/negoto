(** I wrote this module because of a bug I was having with the previous
 * implementation of the File library. Saving a file is implemented as a
 * transactional, with the abort action being to delete the file we're
 * currently handling.
 * The library didn't know which files it had already saved, so if a duplicate
 * file was uploaded it would just overwrite it. The problem occurred when
 * the transaction failed *after* the transactional had been registered, so
 * that if you uploaded a duplicate file and the transaction would fail at some
 * other point in the code the library would delete the already existing file,
 * and the part of the code that managed the already existing file wouldn't
 * know about it.

 * In this version File itself owns the files and external code is only allowed
 * to manage a handle to the files. A handle allows its owner to get a link to
 * the file, and tells File that the file pointed to is being used. When the
 * owner of the handle doesn't need it anymore, it can delete its handle, and
 * a periodic job will eventually delete the actual from the disk, unless it's
 * still being used by someone else or we acquire another handle on it before
 * the periodic cleans it up.
 * This has the nice property that multiple pieces of code that don't know
 * anything about each other can manage their own handle to the same file
 * without worrying of accidentally making the file unavailable for the rest.

 * I could've solved this problem in other ways, but this was the cleanest
 * I could think of and this module was in serious need of a cleanup either
 * way. It's not like the current approach doesn't have its warts, but they're
 * mostly hidden in the implementation so it's good enough for me. *)


type handle
  (** A pointer to a file, which indicates that we're currently using it. *)

val show_handle : show handle
val read_handle : read handle
val sql_handle  : sql_injectable_prim handle
val eq_handle   : eq handle


(*
val set : string -> file -> transaction unit
  (** Save a file with the given filename. *)

val link : string -> url
  (** Get a link to the file with the given filename. *)
*)


val spoiler : url

signature Handler = sig
  con link :: Type
    (** The type of the link we can acquire from the file.
     * Usually it's just an url. *)

  val save : file -> transaction (handle * link)
    (** Save the file to disk (if needed) and acquire a handle to it.
     * Also returns the link, so that we can cache it wherever necessary
     * instead of querying this module hundreds of times on pages that requires
     * lots of link to files. *)

  val link : handle -> transaction (option link)
    (** Return a link to the file being pointed to. *)

  val delete : handle -> transaction unit
    (** Delete the handle to the file, signaling that we don't need it
     * anymore. *)
end


structure Image : Handler
  where con link = { Src : url, Thumb : url }

structure Banner : Handler
  where con link = url

structure Css : Handler
  where con link = url
