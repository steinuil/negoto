DB = test.db
NAME = negoto
FILES = $(NAME).ur $(NAME).urp $(NAME).urs data.ur data.urs log.ur util.ur style.css
URWEB = urweb

all: negoto
	sqlite3 $(DB) < stuff.sql

negoto: negoto.exe $(DB)

negoto.sql negoto.exe: $(FILES)
	$(URWEB) $(NAME) -dbms sqlite -db $(DB)

$(DB): $(NAME).sql
	rm -f $@
	sqlite3 $@ < $<

style.css: style.sass
	sass --sourcemap=none --style=expanded -C $< $@

.PHONY: run
run: negoto
	./negoto.exe

.PHONY: check
check:
	$(URWEB) -tc $(NAME)

.PHONY: clean
clean:
	rm -f $(DB) $(NAME).exe $(NAME).sql style.css

.PHONY: refresh
refresh: clean run
