val isValid : string -> bool

val id : int -> id
  (** Returns an id in the form of post<num>, for example [id 1] returns post1 *)

val toHtml : url -> string -> xbody
  (** Takes the URL to use as base for backlinks. *)

val toHtml' : string -> xbody
  (** Like toHtml, but disables backlinks. *)
