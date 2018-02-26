(* NOTE: the directories should be created as part of the build process. *)
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


signature M = sig
  con link :: Type

  val path : string -> string -> link

  val save : string -> string -> file -> transaction unit

  val delete : string -> string -> transaction unit
end


functor Handler(M : M) : sig
  type link = M.link

  val save : file -> transaction (handle * link)

  val link : handle -> transaction (option link)

  val delete : handle -> transaction unit
end = struct
  table files :
    { Hash : string
    , Mime : string }
    PRIMARY KEY Hash

  table handles :
    { File   : string
    , Handle : handle }
    PRIMARY KEY Handle
    CONSTRAINT File FOREIGN KEY File
      REFERENCES files(Hash)
      ON DELETE CASCADE

  (* Reap zombie files that are not referenced by any handles. *)
  task periodic (5 * 60) = fn () =>
    zombies <- queryL1 (SELECT files.* FROM files
                        LEFT JOIN handles ON handles.File = files.Hash
                        WHERE handles.File IS NULL);
    zombies |> List.app (fn f =>
      M.delete f.Hash f.Mime;
      dml (DELETE FROM files WHERE Hash = {[f.Hash]}))


  con link :: Type = M.link


  fun getHandle hash =
    handle <- nextval handle_Ids;
    dml (INSERT INTO handles (Handle, File) VALUES ({[handle]}, {[hash]}));
    return handle


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
    | Some file => return (Some (M.path file.Hash file.Mime))


  fun delete handle =
    dml (DELETE FROM handles WHERE Handle = {[handle]})


  fun save file =
    let val hash = FileFfi.md5Hash file in
      exists <- oneOrNoRows1 (SELECT * FROM files WHERE files.Hash = {[hash]});
      case exists of
      | Some { Mime = mime, ... } =>
        handle <- getHandle hash;
        return (handle, M.path hash mime)
      | None =>
        let val mime = fileMimeType file in
          M.save hash mime file;
          dml (INSERT INTO files (Hash, Mime) VALUES ({[hash]}, {[mime]}));
          handle <- getHandle hash;
          return (handle, M.path hash mime)
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


  type link = { Src : url, Thumb : url }


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

  type link = url


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

  type link = url


  fun path name _ =
    FileFfi.link css_dir name


  fun save name _ file =
    FileFfi.save css_dir name file


  fun delete name _ =
    FileFfi.delete css_dir name
end)
