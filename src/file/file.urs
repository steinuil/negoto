val saveImage : file -> transaction string

val deleteImage : string -> string -> transaction unit

val linkImage : string -> string -> url

val linkThumb : string -> url


type handle

val show_handle : show handle
val read_handle : read handle
val sql_handle  : sql_injectable_prim handle
val eq_handle   : eq handle

signature Handler = sig
  con link :: Type

  val save : file -> transaction (handle * link)

  val link : handle -> transaction (option link)

  val delete : handle -> transaction unit
end


structure Image  : Handler where con link = { Src : url, Thumb : url }

structure Banner : Handler where con link = url

structure Css    : Handler where con link = url
