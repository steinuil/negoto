fun notBetween str min max =
  let val len = strlen str in
  len > max || len < min
  end

fun msg [t] (str : string) : t =
  error <xml>{[str]}</xml>

fun length [a] [t] (_ : show a) (itm : a) (len : int) : t =
  error <xml>{[itm]} must be longer than {[len]}</xml>

fun between [a] [t] (_ : show a) (item : a) (min : int) (max : int) : t =
  error <xml>{[item]} must be between {[min]} and {[max]} characters long</xml>

fun exactly [a] [t] (_ : show a) (item : a) (amount : int) : t =
  error <xml>{[item]} must be exactly {[amount]} characters long</xml>

fun length0 [a] [t] (_ : show a) (item : a) : t =
  error <xml>{[item]} can't be empty</xml>
