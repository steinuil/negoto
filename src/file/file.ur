val css_dir = "css"
val image_dir = "image"
val thumb_dir = "thumb"


task initialize = fn () =>
  FileFfi.mkdir css_dir;
  FileFfi.mkdir image_dir;
  FileFfi.mkdir thumb_dir


fun saveCss name file =
  if fileMimeType file = "text/css" then
    FileFfi.save css_dir (name ^ ".css") file
  else
    error <xml>Not a CSS file: {txt name}</xml>


fun deleteCss name =
  FileFfi.delete css_dir (name ^ ".css")


fun extOfMime mime = case mime of
  | "image/png" => "png"
  | "image/jpeg" => "jpg"
  | "image/gif" => "gif"
  | x => error <xml>Unsupported mime: {txt x}</xml>


fun saveImage file =
  let val hash = FileFfi.md5Hash file in
    FileFfi.save image_dir (hash ^ "." ^ extOfMime (fileMimeType file)) file;
    return hash
  end


fun deleteImage hash mime =
  FileFfi.delete image_dir (hash ^ "." ^ extOfMime mime);
  FileFfi.delete thumb_dir (hash ^ ".jpg")


fun linkImage hash mime =
  FileFfi.link image_dir (hash ^ "." ^ extOfMime mime)


fun linkThumb hash =
  FileFfi.link thumb_dir (hash ^ ".jpg")


(* @Hack so that the default files load without needing an external server.
 * This makes requests crash when selecting a non-default theme. I better get a
 * test server running soon. *)
fun linkCss name =
  FileFfi.link css_dir (name ^ ".css")
