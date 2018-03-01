(* AKA "blackbird" *)
fun compose2 [a] [b] [c] [d] (f1 : c -> d) (f2 : a -> b -> c) x y =
  f1 (f2 x y)


(* @Fixme give this a new name *)
fun elapsed' t1 t2 =
  let
    val diff = t1 `diffInSeconds` t2

    val (oneMinute, oneHour, oneDay, oneWeek, oneMonth, oneYear) =
      (60, 3600, 86400, 86400 * 7, 86400 * 30, 86400 * 365)

    val (elapsed', unit') =
      if diff < oneMinute then
        (diff, "second")
      else if diff < oneHour then
        (diff / oneMinute, "minute")
      else if diff < oneDay then
        (diff / oneHour, "hour")
      else if diff < oneWeek then
        (diff / oneDay, "day")
      else if diff < oneMonth then
        (diff / oneWeek, "week")
      else if diff < oneYear then
        (diff / oneMonth, "month")
      else
        (diff / oneYear, "year")

    val suffix = if elapsed' <> 1 then "s" else ""
  in
    <xml>{[elapsed']} {[unit']}{[suffix]}</xml>
  end


fun elapsed tim =
  tnow <- now;
  return <xml>{elapsed' tim tnow} ago</xml>


fun interpose [a] (sep : a) (ls : list a) : list a = case ls of
  | [] => ls
  | _ :: [] => ls
  | hd :: rest => hd :: sep :: (interpose sep rest)


fun flip [a] [b] [c] (f : a -> b -> c) (x : b) (y : a) =
  f y x


fun bindOptM [m] (_ : monad m) [a] [b]
    (f2 : a -> m (option b)) (f1 : m (option a)) : m (option b) =
  r1 <- f1;
  case r1 of
  | None   => return None
  | Some x => f2 x


(*
fun mapOptM [m] (_ : monad m) [a] [b]
    (f : a -> m b) (x' : option a) : m (option b) =
  case x' of
  | None => return None
  | Some x =>
    res <- f x;
    return (Some res)


fun mapNoneM [m] (_ : monad m) [a]
    (f2 : m (option a)) (f1 : m (option a)) : m (option a) =
  r1 <- f1;
  case r1 of
  | None => f2
  | Some _ => return r1
*)

fun getM [m] (_ : monad m) [a] (default : a) (f : m (option a)) =
  x <- f;
  return (Option.get default x)


fun oneColOpt [tbl ::: Name] [row ::: {Type}] [col :: Name] [t ::: Type] [[col] ~ row]
    (q : sql_query [] [] [tbl = (row ++ [col = t])] []) =
  query q
    (fn fs _ => return (Some fs.tbl.col))
    None


fun oneCols [tbl ::: Name] [row ::: {Type}] [col :: Name] [t ::: Type] [[col] ~ row]
    (q : sql_query [] [] [tbl = (row ++ [col = t])] []) =
  query q
    (fn fs acc => return (fs.tbl.col :: acc))
    []




    (*
fun rowCount [tbl ::: Name] [row ::: {Type}] t expr =
  { Count = count } <- oneRow (SELECT COUNT( * ) AS Count FROM t WHERE {expr});
  return count
  *)


val getIp =
  ip <- getenv (blessEnvVar "REMOTE_ADDR");
  case ip of
  | None    => error <xml>UNEXPECTED: couldn't access remote IP</xml>
  | Some ip => return ip


fun record_seqOpt [ts ::: {Type}] (fl : folder ts) (r : $(map option ts)) : option $ts =
    @foldR [option] [fn ts => option $ts]
     (fn [nm ::_] [v ::_] [r ::_] [[nm] ~ r] v vs =>
         case (v, vs) of
             (Some v, Some vs) => Some ({nm = v} ++ vs)
           | _ => None)
     (Some {}) fl r
