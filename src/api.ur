open Json


(* Provide implementations of the `json` typeclass for the types we need,
 * since Ur/Web doesn't do record name serialization automatically. *)
val json_time : json time =
  mkJson
    { ToJson   = toSeconds >>> show
    , FromJson = fn x => (readError x, "") (* dummy conversion *) }


val json_url : json url =
  mkJson
    { ToJson = show >>> toJson
    , FromJson = fn x => let val (x, rst) = fromJson' x in (bless x, rst) end }


val json_board : json Data.board =
  json_record { Id = "id", Nam = "name" }


type postFile =
  { Fname   : string
  , Src     : url
  , Thumb   : url
  , Spoiler : bool }

val json_postFile : json postFile =
  json_record
    { Fname   = "filename"
    , Src     = "src"
    , Thumb   = "thumb"
    , Spoiler = "spoiler" }


type catalogThread =
  { Id      : int
  , Board   : string
  , Updated : time
  , Subject : string
  , Count   : int
  , Locked  : bool
  , Nam     : string
  , Time    : time
  , Body    : string
  , Files   : list postFile }

val json_catalogThread : json catalogThread =
  json_record
    { Id      = "id"
    , Board   = "board"
    , Updated = "updated"
    , Subject = "subject"
    , Count   = "count"
    , Locked  = "locked"
    , Nam     = "name"
    , Time    = "time"
    , Body    = "body"
    , Files   = "files" }


val json_Thread : json Data.thread =
  json_record
    { Id      = "id"
    , Updated = "updated"
    , Subject = "subject"
    , Count   = "count"
    , Locked  = "locked"
    , Board   = "board" }


type post =
  { Number : int
  , Nam    : string
  , Time   : time
  , Body   : string
  , Files  : list postFile }

val json_Post : json post =
  json_record
    { Number = "number"
    , Nam    = "name"
    , Time   = "time"
    , Body   = "body"
    , Files  = "files" }


type thread' =
  { Thread : Data.thread, Posts : list post }

val json_thread' : json thread' =
  json_record { Thread = "op", Posts = "posts" }


val json_newsItem : json Admin.newsItem =
  json_record
    { Title  = "title"
    , Author = "author"
    , Time   = "time"
    , Body   = "body" }



fun jsonPage [a] (_ : json a) (x : a) : transaction page =
  returnBlob (textBlob (toJson x)) (blessMime "text/plain")


fun jsonPageM [a] (_ : json a) (f : transaction a) : transaction page =
  x <- f;
  returnBlob (textBlob (toJson x)) (blessMime "text/plain")


fun jsonError (msg : string) : transaction page =
  setHeader (blessResponseHeader "Status") "404 Not Found";
  returnBlob (textBlob (toJson msg)) (blessMime "text/plain")



val boards =
  jsonPageM Data.allBoards


fun catalog board =
  c <- Data.catalog board;
  case c of
  | Some c =>
    jsonPage (List.mp (fn x => x -- #Files ++ { Files = (List.mp (fn f => f -- #Handle) x.Files) }) c)
  | None =>
    jsonError "No such board"


fun thread id =
  t <- Data.thread id;
  case t of
  | Some (t, p) =>
    jsonPage { Thread = t, Posts = List.mp (fn p => p -- #Id -- #Thread -- #Files ++ { Files = List.mp (fn f => f -- #Handle) p.Files }) p }
  | None =>
    jsonError "No such thread"


val news =
  jsonPageM Admin.news


val readme =
  jsonPageM Admin.readme
