open Json


fun json' [m] (_ : monad m) [a] (_ : json a) (f : m a) : m string =
  x <- f;
  return (toJson x)

fun jsonPage [a] (_ : json a) (f : transaction a) : transaction page =
  x <- f;
  returnBlob (textBlob (toJson x)) (blessMime "text/plain")


(* Provide implementations of the `json` typeclass for the types we need,
 * since Ur/Web doesn't do record name serialization automatically. *)
val json_Time : json time =
  mkJson
    { ToJson   = show
    , FromJson = fn x => (readError x, "") (* dummy conversion *) }

val json_Tag : json Data.tag =
  json_record { Nam = "name", Slug = "slug" }

val json_PostFile : json Data.postFile =
  json_record { Hash = "hash", Nam = "name", Ext = "extension", Spoiler = "spoiler" }

val json_Thread : json Data.thread =
  json_record
    { Id      = "id"
    , Updated = "updated"
    , Subject = "subject"
    , Locked  = "locked"
    , Tags    = "boards" }

val json_Post : json Data.post =
  json_record
    { Id     = "id"
    , Thread = "thread"
    , Nam    = "name"
    , Time   = "time"
    , Body   = "body"
    , Files  = "files" }

type thread' = { Op : Data.thread, Posts : list Data.post }
val json_Thread' : json thread' =
  json_record { Op = "op", Posts = "posts" }

val json_CatalogThread : json Data.catalogThread =
  json_record
    { Id      = "id"
    , Updated = "updated"
    , Subject = "subject"
    , Locked  = "locked"
    , Tags    = "boards"
    , Nam     = "name"
    , Time    = "time"
    , Body    = "body"
    , Files   = "files" }


(* The actual endpoints *)
(* TODO: return 404 with an error on error? *)
val boards =
  jsonPage Data.allTags

fun catalog board =
  jsonPage (Data.catalogByTag board)

fun thread id =
  t <- Data.threadById id;
  let val x = case t of
    | Some (t, p) => Some { Op = t, Posts = p }
    | None => None
  in
    jsonPage (return x)
  end
