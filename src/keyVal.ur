table store :
  { Key : string
  , Val : string }
  PRIMARY KEY Key


fun unsafeGet [a] (_ : read a) key =
  { Val = v } <- oneRow1 (SELECT store.Val FROM store WHERE store.Key = {[key]});
  return (readError v)


fun get [a] (_ : read a) key =
  v <- oneOrNoRows1 (SELECT store.Val FROM store WHERE store.Key = {[key]});
  return <| Option.mp (fn x => readError x.Val) v


fun exists key =
  hasRows (SELECT TRUE FROM store WHERE store.Key = {[key]})


fun set [a] (_ : show a) key v =
  p <- exists key;
  if p then
    dml (UPDATE store SET Val = {[show v]} WHERE Key = {[key]})
  else
    dml (INSERT INTO store (Key, Val) VALUES ( {[key]}, {[show v]} ))
