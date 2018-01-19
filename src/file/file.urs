val saveCss : string -> file -> transaction unit

val deleteCss : string -> transaction unit

val saveImage : file -> transaction string

val deleteImage : string -> string -> transaction unit

val linkImage : string -> string -> url

val linkThumb : string -> url

val linkCss : string -> url
