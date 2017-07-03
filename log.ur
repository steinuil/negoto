fun log namespace str =
  timestamp <- now;
  debug <|
    timef "%Y/%m/%d@%H:%M:%S" timestamp
    ^ " [" ^ namespace ^ "] " ^ str
