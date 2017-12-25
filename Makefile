urweb = urweb
sqlite = sqlite3
sass = sass
cc = gcc

db_file = test.db

cc_flags = -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare -Wno-missing-braces
cc_include = -I$(HOME)/.local/brew/include/urweb

negoto_files = data.ur data.urs log.ur negoto.ur negoto.urp negoto.urs util.ur
save_files = save/save.h save/save.urs save/lib.urp


negoto: negoto.exe $(db_file)


# File rules
negoto.exe negoto.sql: $(project_files) $(save_files) style.css save.o
	$(urweb) negoto -dbms sqlite -db $(db_file)

save.o: save/save.c
	$(cc) -c $(cc_flags) $< -o $@ $(cc_include)

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
	rm -f $(db_file) save.o style.css negoto.exe negoto.sql

.PHONY: negoto check run clean
