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
  * [X] parse newlines
  * [ ] parse quote arrows, backlinks, spoilers
  * [ ] parse inter-thread backlinks
  * [ ] URLs
  * [X] buffer library similar to OCaml's
    * or at least fix the post length issue

* Ajax post forms
  * [ ] write AJAX form javascript library
    * is this even possible?

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
  * [X] interface for editing accounts
  * [X] interface for managing themes
  * [X] redo thread page
  * [X] interface for managing your account
  * [X] improve the CSS
  * [X] interface to manage affiliate links

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
  * [X] a nicer error page in its own module
  * [ ] come up with a nice logo
  * [ ] add banners

* Feature completeness overview
  * [X] Account
  * [X] Admin
  * [X] Api
  * [X] Data
    * kinda needs a cleanup
  * [X] KeyVal
  * [ ] Layout
    * manage the favicon
  * [ ] Logger
    * needs some way to select the log level at startup time
    * or not
  * [ ] Negoto
    * ajax forms
    * images
    * form validation
    * css fixes
  * [X] Bcrypt
    * add some tests maybe? how does testing even work in Ur/Web?
  * [ ] File
    * managing the favicon
    * generate thumbnails
  * [ ] Post
  * [X] Uuid


## Advanced features
Wishlist of stuff to maybe work on after the imageboard is stable and usable on
real servers.

* Buffer library
  * [X] C version if I haven't already done it before
  * [ ] javascript version

* [SexpCode](https://web.archive.org/web/20160321174220/http://cairnarvon.rotahall.org/misc/sexpcode.html)
  * [ ] desugaring of post reference and quote into SexpCode
  * [ ] base tags
  * [ ] iterated functions
  * [ ] function composition
  * [ ] higher arity functions
  * [ ] user-defined functions

* [ ] Multiple files in single post

* WebM support
  * [ ] player
  * [ ] thumbnails

* Admin JSON API
  * [ ] OAuth-based authentication
  * [ ] endpoints for all functions on the frontend
  * [ ] some command line tools to interact with the API
