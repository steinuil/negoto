val css_dir = "css"
val image_dir = "image"
val thumb_dir = "thumb"
val banner_dir = "banner"


task initialize = fn () =>
  FileFfi.mkdir css_dir;
  FileFfi.mkdir image_dir;
  FileFfi.mkdir thumb_dir;
  FileFfi.mkdir banner_dir


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


fun saveBanner file =
  let val hash = FileFfi.md5Hash file
      val fname = hash ^ "." ^ extOfMime (fileMimeType file) in
    FileFfi.save banner_dir fname file;
    return fname
  end


fun deleteBanner fname =
  FileFfi.delete banner_dir fname


fun saveImage file =
  let val hash = FileFfi.md5Hash file
      val ext = extOfMime (fileMimeType file) in
    FileFfi.saveImage image_dir thumb_dir (hash ^ "." ^ ext) (hash ^ ".jpg") file;
    return hash
  end


fun deleteImage hash mime =
  FileFfi.delete image_dir (hash ^ "." ^ extOfMime mime);
  FileFfi.delete thumb_dir (hash ^ ".jpg")


fun linkBanner fname =
  FileFfi.link banner_dir fname


fun linkImage hash mime =
  FileFfi.link image_dir (hash ^ "." ^ extOfMime mime)


fun linkThumb hash =
  FileFfi.link thumb_dir (hash ^ ".jpg")


(* @Hack so that the default files load without needing an external server.
 * This makes requests crash when selecting a non-default theme. I better get a
 * test server running soon. *)
fun linkCss name =
  FileFfi.link css_dir (name ^ ".css")


signature M = sig
  val path : string -> string -> string

  val save : string -> string -> file -> transaction unit

  val delete : string -> string -> transaction unit
end


signature Handler = sig
  type handle

  val save : file -> transaction handle

  val link : handle -> transaction (option url)

  val delete : handle -> transaction unit
end


functor Handler(M : M) : Handler = struct
  table files :
    { Hash : string
    , Mime : string }
    PRIMARY KEY Hash

  task periodic (5 * 60) = fn () =>
    (* @Fixme stub *)
    return ()

  sequence handle_Ids

  table handles :
    { File   : string
    , Handle : int }

  type handle = int


  fun getHandle hash =
    handle <- nextval handle_Ids;
    dml (INSERT INTO handles (Handle, File) VALUES ({[handle]}, {[hash]}));
    return handle


  (* Idea: expose this as a join expression so that we can let external
   * queries join on these instead of making hundreds of calls per page *)
  fun fileOfHandle handle =
    file <- oneOrNoRows (SELECT files.* FROM files
                           JOIN handles ON handles.File = files.Hash
                          WHERE handles.Handle = {[handle]});
    case file of
    | None                  => return None
    | Some { Files = file } => return (Some file)


  fun link handle =
    file <- fileOfHandle handle;
    case file of
    | None      => return None
    | Some file => return (Some (bless (M.path file.Hash file.Mime)))


  fun delete handle =
    dml (DELETE FROM handles WHERE Handle = {[handle]})


  fun save file =
    let val hash = FileFfi.md5Hash file in
      exists <- oneOrNoRows1 (SELECT * FROM files WHERE files.Hash = {[hash]});
      case exists of
      | Some _ =>
        getHandle hash
      | None =>
        let val mime = fileMimeType file in
          M.save hash mime file;
          dml (INSERT INTO files (Hash, Mime) VALUES ({[hash]}, {[mime]}));
          getHandle hash
        end
    end
end
