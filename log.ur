datatype level =
  | Debug
  | Info
  | Warning
  | Error


val show_level =
  mkShow (fn x =>
    case x of
    | Debug   => "[DEBUG]"
    | Info    => "[INFO]"
    | Warning => "[WARNING]"
    | Error   => "[ERROR]")


val time =
  timestamp <- now;
  return (timef "%Y/%m/%d %H:%M:%S" timestamp)


fun log section (lvl : level) msg =
  t <- time;
  debug <| t ^ "\t" ^ show lvl ^ "\t" ^ section ^ "\t" ^ msg
