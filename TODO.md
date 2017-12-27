## Version 1.0
A basic frontend that mimics imageboards like 4chan, where threads can only be
associated with one tag, posts can only hold one file and with limited markup
in the post body.

* File handling library
  * [X] save and delete files
  * [ ] generate a filename with an appropriate extension
  * [ ] configure the position of the saved files
  * [ ] return a checksum and image dimensions
  * [ ] process thumbnails for images (and PDFs?) with libvips
    * figure out how to statically link libvips and all its dependencies
  * [ ] process thumbnails for webms with ???

* Post handling library
  * [ ] validate all the post fields
  * [ ] parse newlines, quote arrows and backlinks into some kind of AST
  * [ ] parse spoiler tags too

* Ajax post forms
  * [ ] convert fields to their ajax counterparts
  * [ ] use [ajaxUpload](https://github.com/urweb/ajaxUpload) library for files

* Limits on number of threads and posts
  * [ ] bump old threads off the board
  * [ ] lock threads when they're over their post limit

* Admin control panel
  * [ ] implement admin accounts
  * [ ] interface for deleting boards, posts, threads and files
  * [ ] interface for adding boards
  * [ ] interface for editing the readme file
    * some kind of markup language parser?

* Frontend niceties
  * [ ] clicking on a post number should quote it in the comment box
  * [ ] links to single posts should focus that post in its thread
  * [ ] clicking on an image should expand it inline

* JSON API
  * [ ] boards endpoint
  * [ ] catalog endpoint
  * [ ] thread endpoint


## Advanced frontend
* [SexpCode](https://web.archive.org/web/20160321174220/http://cairnarvon.rotahall.org/misc/sexpcode.html)
  * [ ] desugaring of post reference and quote into SexpCode
  * [ ] base tags
  * [ ] iterated functions
  * [ ] function composition
  * [ ] higher arity functions
  * [ ] user-defined functions
  * [ ] JS version for in-browser live preview
    * maybe write it in OCaml and use C callbacks + `js_of_ocaml`?

* A frontend that supports new features
  * [ ] multiple file forms
  * [ ] filter threads by tags
