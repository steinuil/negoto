datatype t = Ok | Error of string


val show = mkShow (fn x => case x of
  | Ok => "Ok"
  | Error msg => "Error " ^ msg)


fun ofOption x = case x of
  | None => Ok
  | Some err => Error err


fun isOk res : bool =
  case res of Ok => True | Error _ => False


val isError = not <<< isOk


fun mapM [m] (_ : monad m) f2 f1 : m t =
  r1 <- f1;
  case r1 of
  | Ok => f2
  | Error _ => return r1


val dml =
  tryDml >>> Monad.mp ofOption
