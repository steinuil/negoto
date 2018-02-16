# Negoto
Negoto is a simple and functional imageboard. It is mostly written in Ur/Web,
which makes it extremely efficient and lightweight (at least compared to the
more popular PHP-based imageboard), and [ostensibly bug-free](https://github.com/urweb/urweb#the-urweb-programming-language).

[![Build Status](https://travis-ci.org/steinuil/negoto.svg?branch=master)](https://travis-ci.org/steinuil/negoto)

## Does this work?
Not yet. Negoto is still in development, but it'll soon be ready to be deployed.
See [TODO.md](TODO.md) for details on what's not done yet.

## Dependencies
Negoto depends on OpenSSL, and it assumes that `/dev/urandom` exists and is
readable.

## Compiling
The very least Negoto requires to build is:

* gcc
* GNU Make
* [Ur/Web](http://impredicative.com/ur/)

The normal installation also requires:

* [sass](http://sass-lang.com/)
* SQLite3
* lighttpd

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
