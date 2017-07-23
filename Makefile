DB = test.db
NAME = negoto
FILES = $(NAME).ur $(NAME).urp $(NAME).urs data.ur data.urs log.ur util.ur sexpCode.ur sexpCode.urs
URWEB = ~/lam/urweb/bin/urweb

negoto: negoto.exe $(DB)

negoto.sql negoto.exe: $(FILES)
	$(URWEB) $(NAME) -dbms sqlite -db $(DB)

$(DB): $(NAME).sql
	rm -f $(.TARGET)
	sqlite3 $(.TARGET) < $(.ALLSRC)

.PHONY: run
run: negoto
	./negoto.exe

.PHONY: check
check:
	$(URWEB) -tc $(NAME)

.PHONY: clean
clean:
	rm -f $(DB) $(NAME).exe $(NAME).sql

.PHONY: refresh
refresh: clean run
