val md5Hash : file -> string
  (* Compute the md5 hash of a file *)

val save : string -> string -> file -> transaction unit
  (* [save section name file] saves [file] in [section].
   * WARNING: if the section name is longer than 16
   * or the filename is longer than 32 characters,
   * they will be truncated. *)

val saveImage : string -> string -> string -> string -> file -> transaction unit

val delete : string -> string -> transaction unit

val link : string -> string -> url

val mkdir : string -> transaction unit
