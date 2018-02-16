default: negoto


# Compilers
urweb = urweb
sqlite = sqlite3
sass = sass
CC ?= gcc

cc_flags = -Wall -Wextra -Wno-unused-parameter -Wno-implicit-fallthrough -std=gnu11
ur_include = -I$(shell urweb -print-cinclude)

# Source and build dir
s = src
b = build

$b:
	mkdir $b

src = $s/negoto.urp
src += $s/account.ur $s/account.urs
src += $s/admin.ur $s/admin.urs
src += $s/api.ur $s/api.urs
src += $s/data.ur $s/data.urs
src += $s/error.ur
src += $s/keyVal.ur $s/keyVal.urs
src += $s/layout.ur $s/layout.urs
src += $s/logger.ur $s/logger.urs
src += $s/main.ur
src += $s/negoto.ur $s/negoto.urs
src += $s/post.ur $s/post.urs
src += $s/styles.ur
src += $s/tags.urs
src += $s/util.ur
ext =

# File library
src += $s/file/lib.urp
src += $s/file/file.ur $s/file/file.urs
src += $s/file/fileFfi.urs $s/file/fileFfi.h
src += $b/fileFfi.o

$b/fileFfi.o: $s/file/fileFfi.c $s/file/fileFfi.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

# Post library
src += $s/postFfi/lib.urp
src += $s/postFfi/postFfi.urs $s/postFfi/postFfi.h
src += $b/postFfi.o

$b/postFfi.o: $s/postFfi/postFfi.c $s/postFfi/postFfi.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

# UUID library
src += $s/uuid/lib.urp
src += $s/uuid/uuid.urs $s/uuid/uuid.h
src += $b/uuid.o

$b/uuid.o: $s/uuid/uuid.c $s/uuid/uuid.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

# Buffer library
src += $s/buffer/lib.urp
src += $s/buffer/buffer.urs $s/buffer/buffer.h
src += $b/buffer.o

$b/buffer.o: $s/buffer/buffer.c $s/buffer/buffer.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

# Bcrypt
ext += $s/bcrypt/bcrypt.a

.PHONY: $s/bcrypt/bcrypt.a
$s/bcrypt/bcrypt.a: $(bcrypt_lib)
	@$(MAKE) -C $s/bcrypt

# Themes
sass_base = themes/base.sass themes/reset.sass
css = $b/yotsuba.css $b/yotsuba-b.css

$b/%.css: themes/%.sass $(sass_base) | $b
	$(sass) --sourcemap=none --style=expanded -C $< $@


# Main program
exe = negoto.fcgi
db = $b/negoto.db

$b/schema.sql: $(exe) ;
$(exe): project.urp $(src) | $(ext)
	$(urweb) project -protocol fastcgi -dbms sqlite -db $(db) -output $@

$(db): $b/schema.sql init.sql
	rm -f $@
	$(sqlite) $@ < $b/schema.sql
	$(sqlite) $@ < init.sql


negoto: $(exe) $(db)


public/static:
	mkdir -p $@

run: negoto $(css) | public/static
	mkdir -p public/static/css
	cp $(css) public/static/css
	lighttpd -f lighttpd.conf -D


check:
	$(urweb) -tc project

clean:
	rm -rf $b $(exe) public
	@$(MAKE) -C $s/bcrypt clean

pull-submodules:
	git submodule update --recursive --remote

.PHONY: negoto check run clean pull-submodules
