PROG = stats-server

SOURCES = $(PROG).c mongoose.c
CC = /opt/toolchains/uclibc-crosstools-gcc-4.4.2-1/usr/bin/mips-linux-uclibc-gcc
CFLAGS = -g -W -Wall -Werror -Wno-unused-function -s -static

$(PROG): $(SOURCES)
	$(CC) $(SOURCES) -o $@ $(CFLAGS)

clean:
	rm $(PROG)
