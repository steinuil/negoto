- [ ] frontend that mimics the old negoto, using only part of the features

- [ ] new frontend that uses all features

- [ ] C library that:
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

