urweb = urweb
sqlite = sqlite3
sass = sass
CC ?= gcc

db_file = test.db

cc_flags = -Wall -Wextra -Wno-unused-parameter -Wno-implicit-fallthrough -std=gnu11
ur_include = -I$(shell urweb -print-cinclude)

negoto_files = data.ur data.urs negoto.ur negoto.urp negoto.urs util.ur api.ur api.urs admin.ur logger.ur logger.urs
file_lib = file/file.h file/file.urs file/lib.urp
post_lib = post/post.urs post/post.ur post/lib.urp
uuid_lib = uuid/uuid.urs uuid/uuid.h uuid/lib.urp


negoto: negoto.exe $(db_file)


# File rules
negoto.exe schema.sql: $(negoto_files) style.css $(file_lib) file.o $(post_lib) postFfi.o $(uuid_lib) uuid.o
	$(urweb) negoto -dbms sqlite -db $(db_file)

uuid.o: uuid/uuid.c uuid/uuid.h
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

file.o: file/file.c file/file.h
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

postFfi.o: post/postFfi.c post/postFfi.h
	$(CC) -c $(cc_flags) $< -o $@ $(ur_include)

style.css: style.sass
	$(sass) --sourcemap=none --style=expanded -C $< $@

$(db_file): schema.sql init.sql
	rm -f $@
	$(sqlite) $@ < schema.sql
	$(sqlite) $@ < init.sql


# Phony rules
check:
	$(urweb) -tc negoto

run: negoto
	./negoto.exe

clean:
	rm -f $(db_file) *.o style.css negoto.exe schema.sql

.PHONY: negoto check run clean
