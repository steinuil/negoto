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
