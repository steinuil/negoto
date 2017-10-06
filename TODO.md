- [ ] frontend that mimics the old negoto, using only part of the features

- [ ] new frontend that uses all features

- [ ] external library that:
  - saves files
  - processes their thumbnails
  - returns some info (dimensions?)
  - deletes them on demand

- [ ] pull in libvpx to support webms
  - actually we need something to demux webms too

- [X] [sexpcode](http://cairnarvon.rotahall.org/misc/sexpcode.html) library
  - [X] add a "post" function of arity 2 to link to a post
  - [ ] have `>>num` desugar to `{post <thread> <num>}`
  - [ ] and `>text` desugar to `{quote|text}`


Ur/Web fucking sucks for doing operations on strings. Even calling fucking strlen makes the server allocate everybody and their dog on the heap and makes it double its size at least a dozen times in a single request, so it's better to pull all that shit off. The functions operating on strings are painfully minimalistic anyway.

- [ ] throw away all the stuff involving strings and put it in external libraries
  - [ ] reimplement validation
  - [ ] reimplement sexpcode (make it still output some sexpcode AST)
  - [ ] maybe find out how to do it in OCaml with minimal C glue code
    - the sexpcode library would be great to implement in OCaml because you could compile it to JS with bucklescript or js\_of\_ocaml
