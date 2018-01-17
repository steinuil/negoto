val save : string -> string -> file -> transaction unit

val delete : string -> string -> transaction unit

val saveImage : string -> file -> transaction string
  (* [saveImage mime file] saves an image
   * and returns a struct thing. *)

val link : string -> string -> url
