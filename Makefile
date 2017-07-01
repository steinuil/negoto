DB = test.db
NAME = negoto

negoto: negoto.exe $(DB)

negoto.sql negoto.exe: $(NAME).ur $(NAME).urp $(NAME).urs data.ur data.urs log.ur log.urs
	urweb $(NAME) -dbms sqlite -db $(DB)

$(DB): $(NAME).sql
	rm -f $(.TARGET)
	sqlite3 $(.TARGET) < $(.ALLSRC)

.PHONY: run
run: negoto
	./negoto.exe

.PHONY: check
check:
	urweb -tc $(NAME)

.PHONY: clean
clean:
	rm -f $(DB) $(NAME).exe $(NAME).sql
