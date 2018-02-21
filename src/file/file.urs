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


signature Handler = sig
  type handle

  con link :: Type

  val save : file -> transaction (handle * link)

  val link : handle -> transaction (option link)

  val delete : handle -> transaction unit
end


structure Image  : Handler where con link = { Src : url, Thumb : url }

structure Banner : Handler where con link = url

structure Css    : Handler where con link = url
