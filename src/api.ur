open Json


fun jsonPage [a] (_ : json a) (x : a) : transaction page =
  returnBlob (textBlob (toJson x)) (blessMime "text/plain")

fun jsonPageM [a] (_ : json a) (f : transaction a) : transaction page =
  x <- f;
  returnBlob (textBlob (toJson x)) (blessMime "text/plain")

fun jsonError (msg : string) : transaction page =
  setHeader (blessResponseHeader "Status") "404 Not Found";
  returnBlob (textBlob (toJson msg)) (blessMime "text/plain")


(* Provide implementations of the `json` typeclass for the types we need,
 * since Ur/Web doesn't do record name serialization automatically. *)
val json_Time : json time =
  mkJson
    { ToJson   = toSeconds >>> show
    , FromJson = fn x => (readError x, "") (* dummy conversion *) }

val json_Tag : json Data.tag =
  json_record { Nam = "name", Slug = "slug" }

val json_PostFile : json Data.postFile =
  json_record { Hash = "hash", Nam = "name", Mime = "mimetype", Spoiler = "spoiler" }

val json_Thread : json Data.thread =
  json_record
    { Id      = "id"
    , Updated = "updated"
    , Subject = "subject"
    , Count   = "count"
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

type thread' = { Thread : Data.thread, Posts : list Data.post }
val json_Thread' : json thread' =
  json_record { Thread = "op", Posts = "posts" }

val json_CatalogThread : json Data.catalogThread =
  json_record
    { Id      = "id"
    , Updated = "updated"
    , Subject = "subject"
    , Count   = "count"
    , Locked  = "locked"
    , Tags    = "boards"
    , Nam     = "name"
    , Time    = "time"
    , Body    = "body"
    , Files   = "files" }

val json_newsItem : json Admin.newsItem =
  json_record
    { Title  = "title"
    , Author = "author"
    , Time   = "time"
    , Body   = "body" }

val json_readme : json Admin.readme =
  json_record
    { Body    = "body"
    , Updated = "updated" }


(* The actual endpoints *)
(* TODO: return 404 with an error on error? *)
val boards =
  jsonPageM Data.allTags

fun catalog board =
  c <- Data.catalogByTag' board;
  case c of
  | Some cat => jsonPage cat
  | None => jsonError "No such board"

fun thread id =
  t <- Data.threadById id;
  case t of
  | Some (t, p) =>
    jsonPage { Thread = t, Posts = p }
  | None =>
    jsonError "No such thread"

val news =
  jsonPageM Admin.news

val readme =
  jsonPageM Admin.readme
