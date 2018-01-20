table store :
  { Key : string
  , Val : string }
  PRIMARY KEY Key


fun unsafeGet key =
  { Val = v } <- oneRow1 (SELECT store.Val FROM store WHERE store.Key = {[key]});
  return v


fun get key =
  v <- oneOrNoRows1 (SELECT store.Val FROM store WHERE store.Key = {[key]});
  return (Option.mp (fn x => x.Val) v)


fun exists key =
  hasRows (SELECT TRUE FROM store WHERE store.Key = {[key]})


fun set key v =
  p <- exists key;
  if p then
    dml (UPDATE store SET Val = {[v]} WHERE Key = {[key]})
  else
    dml (INSERT INTO store (Key, Val) VALUES ( {[key]}, {[v]} ))
