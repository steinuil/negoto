val id : int -> id
  (** Returns an id in the form of post<num>, for example [id 1] returns post1 *)

val link : id -> url

val toHtml : string -> transaction xbody
