## Version 1.0
A basic frontend that mimics imageboards like 4chan, where threads can only be
associated with one tag, posts can only hold one file and with limited markup
in the post body.

* File handling library
  * [X] save and delete files
  * [X] generate a filename with an appropriate extension
  * [ ] configure the position of the saved files
    * how??
  * [X] return a checksum and image dimensions
  * [ ] process thumbnails for images with libvips
    * figure out how to statically link libvips and all its dependencies

* Post handling library
  * [ ] validate all the post fields
  * [X] parse newlines, quote arrows, backlinks, spoilers
  * [ ] parse inter-thread backlinks
  * [ ] URLs

* Ajax post forms
  * [X] convert fields to their ajax counterparts
  * [ ] use [ajaxUpload](https://github.com/urweb/ajaxUpload) library for files

* Limits on number of threads and posts
  * [X] bump old threads off the board
  * [X] lock threads when they're over their post limit

* Admin control panel
  * [X] implement admin accounts
  * [X] restrict admin privileges to admins
  * [X] interface for deleting boards, posts, threads and files
  * [X] interface for adding boards
  * [X] interface for editing the readme file
  * [X] interface for adding/deleting news
  * [X] interface for editing news
  * [ ] interface for editing accounts
  * [ ] interface for managing themes
  * [ ] improve the CSS

* Frontend niceties
  * [X] clicking on a post number should quote it in the comment box
  * [X] links to single posts should focus that post in its thread
  * [X] clicking on an image should expand it inline

* JSON API
  * [X] boards endpoint
  * [X] catalog endpoint
  * [X] thread endpoint
  * [X] include API links without linking it from the readme page
  * [X] readme endpoint
  * [X] return proper HTTP statuses on error
    * this is only possible with the CGI modes
  * [X] news endpoint

* News
  * [X] show some news on the front page

* Other
  * [X] deleting the OP should delete the rest of the thread
  * [X] improve CSS, add different themes
  * [X] add cookie to switch themes
  * [ ] validate all forms


## Advanced features
* [SexpCode](https://web.archive.org/web/20160321174220/http://cairnarvon.rotahall.org/misc/sexpcode.html)
  * [ ] desugaring of post reference and quote into SexpCode
  * [ ] base tags
  * [ ] iterated functions
  * [ ] function composition
  * [ ] higher arity functions
  * [ ] user-defined functions
  * [ ] JS version for in-browser live preview
    * maybe write it in OCaml and use C callbacks + `js_of_ocaml`?

* [ ] Multiple files in single post

* WebM support
  * [ ] player
  * [ ] thumbnails
