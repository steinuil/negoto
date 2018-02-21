val saveCss : string -> file -> transaction unit

val deleteCss : string -> transaction unit

val saveBanner : file -> transaction string

val deleteBanner : string -> transaction unit

val saveImage : file -> transaction string

val deleteImage : string -> string -> transaction unit

val linkBanner : string -> url

val linkImage : string -> string -> url

val linkThumb : string -> url

val linkCss : string -> url


signature M = sig
  val path : string -> string -> string

  val save : string -> string -> file -> transaction unit

  val delete : string -> string -> transaction unit
end


signature Handler = sig
  (**  *)

  type handle
  (** A handle to a file. *)

  val save : file -> transaction handle
  (** Save a file and get back a handle. *)

  val link : handle -> transaction (option url)

  val delete : handle -> transaction unit
end


functor Handler(M : M) : Handler
