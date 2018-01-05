datatype level = Debug | Info | Warning | Error


val show_level =
  mkShow (fn x =>
    case x of
    | Debug   => "DEBUG"
    | Info    => "INFO"
    | Warning => "WARNING"
    | Error   => "ERROR")


(*
fun string_of_level x =
  case x of
  | "DEBUG" => Some Debug     | "debug" => Some Debug
  | "INFO" => Some Info       | "info" => Some Info
  | "WARNING" => Some Warning | "warning" => Some Warning
  | "ERROR" => Some Error     | "error" => Some Error
  | _ => None


val read_level =
  mkRead
    (fn x => case string_of_level x of
      | Some l => l
      | None => error <xml>Invalid log level: {[x]}</xml>)
    string_of_level


fun int_of_level x =
  case x of Debug => 0 | Info => 1 | Warning => 2 | Error => 3


val ord_level =
  mkOrd
    { Lt = fn x y => lt (int_of_level x) (int_of_level y)
    , Le = fn x y => le (int_of_level x) (int_of_level y) }


val logLevel = blessEnvVar "NEGOTO_LOGLEVEL"


fun shouldLog (lvl : level) : transaction bool =
  s <- getenv logLevel;
  case Option.bind read s of
  | Some l =>
    return (lvl >= l)
  | None =>
    return (lvl > Debug)
*)


signature M = sig
  val section : string
end


functor Make(M : M) = struct
  val time =
    timestamp <- now;
    return (timef "%Y/%m/%d %H:%M:%S" timestamp)

  fun log lvl msg =
    t <- time;
    debug <| t ^ "\t" ^ show lvl ^ "\t" ^ M.section ^ "\t" ^ msg

  val debug   = log Debug
  val info    = log Info
  val warning = log Warning
  val error   = log Error
end
