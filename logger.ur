datatype level = Debug | Info | Warning | Error


val show_level =
  mkShow (fn x =>
    case x of
    | Debug   => "DEBUG"
    | Info    => "INFO"
    | Warning => "WARNING"
    | Error   => "ERROR")


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
