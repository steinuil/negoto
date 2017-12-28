urweb = urweb
sqlite = sqlite3
sass = sass
CC ?= gcc

db_file = test.db

cc_flags = -Wall -Wextra -Wno-unused-parameter -Wno-implicit-fallthrough -std=gnu11
ur_include = -I$(shell urweb -print-cinclude)

negoto_files = data.ur data.urs log.ur negoto.ur negoto.urp negoto.urs util.ur
file_lib = file/file.h file/file.urs file/lib.urp
post_lib = post/post.urs post/post.ur post/lib.urp


negoto: negoto.exe $(db_file)


# File rules
negoto.exe negoto.sql: $(negoto_files) style.css $(file_lib) file.o $(post_lib) postFfi.o
	$(urweb) negoto -dbms sqlite -db $(db_file)

file.o: file/file.c
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

postFfi.o: post/postFfi.c post/postFfi.h
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

style.css: style.sass
	$(sass) --sourcemap=none --style=expanded -C $< $@

$(db_file): negoto.sql init.sql
	rm -f $@
	$(sqlite) $@ < negoto.sql
	$(sqlite) $@ < init.sql


# Phony rules
check:
	$(urweb) -tc negoto

run: negoto
	./negoto.exe

clean:
	rm -f $(db_file) *.o style.css negoto.exe negoto.sql

.PHONY: negoto check run clean
