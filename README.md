# Negoto
Negoto is a simple and functional imageboard. It is mostly written in Ur/Web,
which makes it extremely efficient and lightweight (at least compared to the
more popular PHP-based imageboard), and [ostensibly bug-free](https://github.com/urweb/urweb#the-urweb-programming-language).

[![Build Status](https://travis-ci.org/steinuil/negoto.svg?branch=master)](https://travis-ci.org/steinuil/negoto)

## Does this work?
Sort of. It runs fine on my server, but if you want to run it on yours you'll
have to configure a few things (the paths in fileFfi.c, fileFfi.js, project.urp
and bring your own lighttpd.conf file). There's also a few features that I'd
like the 1.0 version to have, along with some small bugs to fix.

If you want to use it and have trouble installing it, feel free to open an
issue and I'll try to get back to it and maybe finish it asap.

## Dependencies
Negoto depends on OpenSSL, and it assumes that `/dev/urandom` exists and is
readable.

## Compiling
The very least Negoto requires to build is:

* gcc
* GNU Make
* [Ur/Web](http://impredicative.com/ur/)

There's some bugs with SQLite that at the moment are only fixed in
[my fork](https://github.com/steinuil/urweb/tree/sqlite-fix) on the branch
`sqlite-fix`, so you should build with that for the moment.

The normal installation also requires:

* [sass](http://sass-lang.com/)
* SQLite3
* lighttpd
* ImageMagick's `convert` in your $PATH

To compile, simply clone the repository and invoke make:

```
git clone --recursive https://github.com/steinuil/negoto
cd negoto && make
```

To test it out, invoke make again:

```
make run
```

...and navigate to `localhost:8080/negoto/Negoto/front` on your browser.

## JSON API
Negoto comes with a read-only JSON API. The endpoints are described in [API.md](API.md).
