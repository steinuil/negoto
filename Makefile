urweb = urweb
sqlite = sqlite3
sass = sass
CC ?= gcc

db_file = test.db

cc_flags = -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare -Wno-missing-braces
cc_include = -I$(HOME)/.local/brew/include/urweb

negoto_files = data.ur data.urs log.ur negoto.ur negoto.urp negoto.urs util.ur
file_lib = file/file.h file/file.urs file/lib.urp


negoto: negoto.exe $(db_file)


# File rules
negoto.exe negoto.sql: $(negoto_files) $(file_lib) style.css file.o
	$(urweb) negoto -dbms sqlite -db $(db_file)

file.o: file/file.c
	$(CC) -c $(cc_flags) $< -o $@ $(cc_include) $(URWEB_INCLUDES)

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
	rm -f $(db_file) file.o style.css negoto.exe negoto.sql

.PHONY: negoto check run clean
