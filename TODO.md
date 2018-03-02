## Version 1.0
* Handle images in a better way
  * [ ] use a library for processing images instead of invoking ImageMagick
  * [ ] return some image info like width/height and thumbnail width/height

* Options for processing images are:
  * libvips (only compiles to a libtool library, gross API)
  * ImageMagick (xboxhueg, don't really know if I'd want to link it statically)
  * GraphicsMagick (similar problems to IM, had problems with certain kinds of images in the past)
  * stb\_image/SOIL (don't handle problematic images very well)
  * DevIL (probably the best out of the bunch)

* Handle some markup
  * [X] backlinks
  * [X] spoilers
  * [ ] urls
  * [ ] inter-thread backlinks

* Ajax post forms
  * [ ] either use ajaxUpload or roll my own library

* Handle IPs and bans (env variable `REMOTE_ADDR`)
  * [X] store post IPs for a while and remove them from the db after a day or so
  * [X] posting cooldown
  * [ ] IP bans
  * [ ] IP region bans (?)

* Other
  * [X] purge old files from the database in some other way
  * [ ] a preprocessor that lets you configure paths in fileFfi.c, fileFfi.js, project.urp, lighttpd.conf and css file hashes in init.sql
  * [X] convert all the `CURRENT_TIMESTAMP` into machine time, because SQLite uses UTC
  * [X] handle spoilered images
  * [ ] come up with a nice logo
  * [ ] add default favicon
  * [ ] add default spoiler image


## Wishlist
* Rewrite the admin panel so that modules can define their own panels without exposing unnecessary data to the rest of the app

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

* Live preview of post

* [ ] Less relevant news such as scheduled downtime, hidden on the front page but shown in a blotter

* [ ] Multiple files in single post

* Manage files with an immutable URL (favicon, other stuff)
  * [ ] write a key-value interface to File, use symlinks to avoid deleting stuff
  * [ ] manage the favicon
  * [ ] manage the spoiler fallback image

* WebM support
  * [ ] player
  * [ ] thumbnails

* Admin JSON API
  * [ ] OAuth-based authentication
  * [ ] endpoints for all functions on the frontend
  * [ ] some command line tools to interact with the API
