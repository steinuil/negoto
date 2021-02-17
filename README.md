# Negoto

Negoto is a futaba-style imageboard written in [Ur/Web](http://www.impredicative.com/ur/).
It features:

* Basic imageboard stuff (boards, threads, posts, images, spoilers, post markup, sage, etc)
* A read-only JSON API
* An extensive admin panel
* Themes

[![Build Status](https://travis-ci.org/steinuil/negoto.svg?branch=master)](https://travis-ci.org/steinuil/negoto)

## Project status

Negoto is fully functional and I have the latest version deployed on my server.
It is a bit complicated to configure, and since it only runs on FastCGI requires
a bit of setup to run on nginx.  There's also a few features that I'd like the
1.0 version to have, along with some small bugs to fix.

## Compiling

The very least Negoto requires to build is:

* gcc
* GNU Make
* [Ur/Web](http://impredicative.com/ur/)
* SQLite3
* [sass](http://sass-lang.com/)

The normal installation also requires:

* ImageMagick's `convert` in the $PATH (or set the path in NEGOTO_CONVERT_PATH in negoto_config.h)

To compile, simply clone the repository and invoke make:

```
git clone --recursive https://github.com/steinuil/negoto
cd negoto && make
```

## JSON API

Negoto comes with a read-only JSON API. The endpoints are described in [API.md](API.md).
