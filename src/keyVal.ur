table store :
  { Key : string
  , Val : string }
  PRIMARY KEY Key


fun get key =
  { Val = v } <- oneRow1 (SELECT store.Val FROM store WHERE store.Key = {[key]});
  return v


fun exists key =
  hasRows (SELECT TRUE FROM store WHERE store.Key = {[key]})


fun set key v =
  p <- exists key;
  if p then
    dml (UPDATE store SET Val = {[v]} WHERE Key = {[key]})
  else
    dml (INSERT INTO store (Key, Val) VALUES ( {[key]}, {[v]} ))
