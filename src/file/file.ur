val image_dir = "image"
val thumb_dir = "thumb"


task initialize = fn () =>
  FileFfi.mkdir image_dir;
  FileFfi.mkdir thumb_dir


fun extOfMime mime = case mime of
  | "image/png" => "png"
  | "image/jpeg" => "jpg"
  | "image/gif" => "gif"
  | x => error <xml>Unsupported mime: {txt x}</xml>


fun saveImage file =
  let val hash = FileFfi.md5Hash file
      val ext = extOfMime (fileMimeType file) in
    FileFfi.saveImage image_dir thumb_dir (hash ^ "." ^ ext) (hash ^ ".jpg") file;
    return hash
  end


fun deleteImage hash mime =
  FileFfi.delete image_dir (hash ^ "." ^ extOfMime mime);
  FileFfi.delete thumb_dir (hash ^ ".jpg")


fun linkImage hash mime =
  FileFfi.link image_dir (hash ^ "." ^ extOfMime mime)


fun linkThumb hash =
  FileFfi.link thumb_dir (hash ^ ".jpg")



signature M = sig
  con link :: Type

  val basename : file -> string

  val path : string -> string -> link

  val save : string -> string -> file -> transaction unit

  val delete : string -> string -> transaction unit
end


type handle = int

val show_handle = show_int
val read_handle = read_int
val sql_handle  = sql_int
val eq_handle   = eq_int

sequence handle_Ids


signature Handler = sig
  con link :: Type

  val save : file -> transaction (handle * link)

  val link : handle -> transaction (option link)

  val delete : handle -> transaction unit
end


functor Handler(M : M) : sig
  type link = M.link

  val save : file -> transaction (handle * link)

  val link : handle -> transaction (option link)

  val delete : handle -> transaction unit
end = struct
  table files :
    { Nam  : string
    , Mime : string }
    PRIMARY KEY Nam

  table handles :
    { File   : string
    , Handle : handle }
    PRIMARY KEY Handle
    CONSTRAINT File FOREIGN KEY File
      REFERENCES files(Nam)
      ON DELETE CASCADE

  (* Delete the files that have no handles attached every 5 minutes. *)
  task periodic (5 * 60) = fn () =>
    names <- query (SELECT DISTINCT handles.File FROM handles)
               (fn { Handles = { File = file } } acc =>
                 return (file :: acc)) [];
    let fun many acc (ls : list string) = case ls of
      | []      => acc
      | x :: xs => many (WHERE t.Nam <> {[x]} AND {acc}) xs
    in
      xs <- queryL (SELECT * FROM files AS T WHERE {many (WHERE TRUE) names});
      List.app (fn { T = x } => M.delete x.Nam x.Mime) xs;
      dml (DELETE FROM files WHERE {many (WHERE TRUE) names})
    end


  con link :: Type = M.link


  fun getHandle name =
    handle <- nextval handle_Ids;
    dml (INSERT INTO handles (Handle, File) VALUES ({[handle]}, {[name]}));
    return handle


  fun fileOfHandle handle =
    file <- oneOrNoRows (SELECT files.* FROM files
                           JOIN handles ON handles.File = files.Nam
                          WHERE handles.Handle = {[handle]});
    case file of
    | None                  => return None
    | Some { Files = file } => return (Some file)


  fun link handle =
    file <- fileOfHandle handle;
    case file of
    | None      => return None
    | Some file => return (Some (M.path file.Nam file.Mime))


  fun delete handle =
    dml (DELETE FROM handles WHERE Handle = {[handle]})


  fun save file =
    let val basename = M.basename file in
      exists <- oneOrNoRows1 (SELECT * FROM files WHERE files.Nam = {[basename]});
      case exists of
      | Some { Mime = mime, ... } =>
        handle <- getHandle basename;
        return (handle, M.path basename mime)
      | None =>
        let val mime = fileMimeType file in
          M.save basename mime file;
          dml (INSERT INTO files (Nam, Mime) VALUES ({[basename]}, {[mime]}));
          handle <- getHandle basename;
          return (handle, M.path basename mime)
        end
    end
end


fun extOfMimeImg mime = case mime of
  | "image/jpeg" => "jpg"
  | "image/png"  => "png"
  | "image/gif"  => "gif"
  | x => error <xml>Unsupported mime: {[mime]}</xml>


structure Image = Handler(struct
  val thumb_dir = "t"
  val image_dir = "s"

  task initialize = fn () =>
    FileFfi.mkdir thumb_dir;
    FileFfi.mkdir image_dir


  type link = { Src : url, Thumb : url }


  fun basename file =
    FileFfi.md5Hash file


  fun path hash mime =
    { Src   = FileFfi.link image_dir (hash ^ "." ^ extOfMimeImg mime)
    , Thumb = FileFfi.link thumb_dir (hash ^ ".jpg") }


  fun save hash mime file =
    FileFfi.saveImage image_dir thumb_dir
      (hash ^ "." ^ extOfMimeImg mime) (hash ^ ".jpg") file


  fun delete hash mime =
    FileFfi.delete image_dir (hash ^ "." ^ extOfMimeImg mime);
    FileFfi.delete thumb_dir (hash ^ ".jpg")
end)



structure Banner = Handler(struct
  val banner_dir = "banner"

  task initialize = fn () =>
    FileFfi.mkdir banner_dir

  type link = url


  fun basename file =
    FileFfi.md5Hash file


  fun fname hash mime = hash ^ "." ^ extOfMimeImg mime


  fun path hash mime =
    FileFfi.link banner_dir (fname hash mime)


  fun save hash mime file =
    FileFfi.save banner_dir (fname hash mime) file


  fun delete hash mime =
    FileFfi.delete banner_dir (fname hash mime)
end)



structure Css = Handler(struct
  val css_dir = "css"

  task initialize = fn () =>
    FileFfi.mkdir css_dir

  type link = url


  fun basename file =
    case fileName file of
    | Some n => n
    | None => error <xml>The uploaded file has no name!</xml>


  fun path name _ =
    FileFfi.link css_dir name


  fun save name _ file =
    FileFfi.save css_dir name file


  fun delete name _ =
    FileFfi.delete css_dir name
end)
