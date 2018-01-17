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

file_lib = $s/file/lib.urp $s/file/file.urs $s/file/file.ur $s/file/fileFfi.urs $s/file/fileFfi.h
post_lib = $s/post/lib.urp $s/post/post.urs $s/post/post.ur $s/post/postFfi.urs $s/post/postFfi.h
uuid_lib = $s/uuid/lib.urp $s/uuid/uuid.urs $s/uuid/uuid.h
src_files = $s/negoto.urp $s/account.ur $s/account.urs $s/admin.ur $s/admin.urs $s/api.ur $s/api.urs $s/data.ur $s/data.urs $s/layout.ur $s/layout.urs $s/logger.ur $s/logger.urs $s/main.ur $s/negoto.ur $s/negoto.urs $s/tags.urs $s/util.ur $(file_lib) $(post_lib) $(uuid_lib)

sass_base = themes/base.sass themes/reset.sass
css_files = $b/yotsuba.css $b/yotsuba-b.css

# Outputs
db = test.db
exe = negoto.exe


negoto: $(exe) $(db)

# Because make is stupid and will run urweb twice with -j >1
$b/schema.sql: $(exe) ;
$(exe): $(src_files) $b/fileFfi.o $b/postFfi.o $b/uuid.o $b/yotsuba.css $b/yotsuba-b.css
	$(urweb) project -dbms sqlite -db $(db) -output negoto.exe

$(db): $b/schema.sql init.sql
	rm -f $@
	$(sqlite) $@ < $b/schema.sql
	$(sqlite) $@ < init.sql

$b/yotsuba.css: themes/yotsuba.sass $(sass_base) | $b
	$(sass) --sourcemap=none --style=expanded -C $< $@

$b/yotsuba-b.css: themes/yotsuba-b.sass $(sass_base) | $b
	$(sass) --sourcemap=none --style=expanded -C $< $@

$b/fileFfi.o: $s/file/fileFfi.c $s/file/fileFfi.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

$b/postFfi.o: $s/post/postFfi.c $s/post/postFfi.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

$b/uuid.o: $s/uuid/uuid.c $s/uuid/uuid.h | $b
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

$b:
	mkdir $b


check:
	$(urweb) -tc project

run: negoto
	./$(exe)

clean:
	rm -rf $b $(exe) $(db)

.PHONY: negoto check run clean
