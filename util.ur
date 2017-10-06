(* AKA "blackbird" *)
fun compose2 [a] [b] [c] [d] (f1 : c -> d) (f2 : a -> b -> c) x y =
  f1 (f2 x y)


fun elapsed tim =
  tnow <- now;
  let
    val diff = tim `diffInSeconds` tnow

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

    val suffix = if elapsed' <> 0 then "s" else ""
  in
    return <xml>{[elapsed']} {[unit']}{[suffix]} ago</xml>
  end


fun interpose [a] (sep : a) (ls : list a) : list a = case ls of
  | [] => ls
  | _ :: [] => ls
  | hd :: rest => hd :: sep :: (interpose sep rest)


fun flip [a] [b] [c] (f : a -> b -> c) (x : b) (y : a) =
  f y x


fun mapNoneM [m] (_ : monad m) [a]
    (f2 : m (option a)) (f1 : m (option a)) : m (option a) =
  r1 <- f1;
  case r1 of
  | None => f2
  | Some _ => return r1
