fun strfold [a] (f : char -> a -> a) acc s =
  let
    fun loop i acc =
      if i < 0
      then acc
      else loop (i - 1) (f (strsub s i) acc)
  in
    loop (strlen s - 1) acc
  end


fun strlist s : list char =
  strfold (fn x acc => x :: acc) [] s


fun strmap (f : char -> char) (s : string) : string =
  strfold (fn x acc => str1 (f x) ^ acc) "" s


val strToUpper =
  strmap Char.toUpper


fun joinStrings sep ls : string =
  let
    fun loop ls acc =
      case ls of
        []      => acc
      | x :: [] => acc ^ x
      | x :: rs => loop rs (acc ^ x ^ sep)
  in
    loop ls ""
  end


fun head [a] (ls : list a) : option a =
  case ls of
    x :: _ => Some x
  | [] => None


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

    val unit' = if elapsed' <> 0 then unit' ^ "s" else unit'
  in
    return (show elapsed' ^ " " ^ unit' ^ " ago")
  end
