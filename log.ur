fun pad2 num =
  if num < 10
  then "0" ^ show num
  else show num

fun formatTime tim = pad2 (datetimeYear   tim)
  ^ "/" ^ pad2 (datetimeMonth  tim)
  ^ "/" ^ pad2 (datetimeDay    tim)
  ^ "@" ^ pad2 (datetimeHour   tim)
  ^ ":" ^ pad2 (datetimeMinute tim)
  ^ ":" ^ pad2 (datetimeSecond tim)

fun log namespace str =
  timestamp <- now;
  debug <| formatTime timestamp ^ " [" ^ namespace ^ "] " ^ str
