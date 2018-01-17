fun saveCss name file =
  if fileMimeType file = "text/css" then
    FileFfi.save "css" (name ^ ".css") file
  else
    error <xml>Not a CSS file: {[name]}</xml>


fun deleteCss name =
  FileFfi.delete "css" (name ^ ".css")


fun extOfMime mime = case mime of
  | "image/png" => "png"
  | "image/jpeg" => "jpg"
  | "image/gif" => "gif"
  | x => error <xml>Unsupported mime: {[x]}</xml>


fun saveImage file =
  str <- FileFfi.saveImage (extOfMime (fileMimeType file)) file;
  let val hash = substring str 0 31
      val width : int = readError (substring str 32 4)
      val height : int = readError (substring str 36 4) in
    debug ("hash: " ^ hash);
    debug ("width: " ^ show width);
    debug ("height: " ^ show height);
    return hash
  end


fun deleteImage hash mime =
  FileFfi.delete "image" (hash ^ "." ^ extOfMime mime);
  FileFfi.delete "thumb" (hash ^ ".jpg")


fun linkImage hash mime =
  FileFfi.link "image" (hash ^ "." ^ extOfMime mime)


fun linkThumb hash =
  FileFfi.link "thumb" (hash ^ ".jpg")
