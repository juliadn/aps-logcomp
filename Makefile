CC = gcc
CFLAGS = -Wall -g

all: airlang

airlang: lex.yy.c airlang.tab.c
	$(CC) $(CFLAGS) -o airlang lex.yy.c airlang.tab.c -lfl

airlang.tab.c airlang.tab.h: airlang.y
	bison -d airlang.y

lex.yy.c: airlang.l airlang.tab.h
	flex airlang.l

clean:
	rm -f airlang lex.yy.c airlang.tab.c airlang.tab.h

.PHONY: all clean