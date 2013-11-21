CC              = gcc

SVNVERS         = $(shell head -n4 .svn/entries | tail -n1)
UNAME           = $(shell uname)
CFLAGS          = -Wall -g -O -I/opt/local/include -Ihidapi -DSVNVERSION='"$(SVNVERS)"'
LDFLAGS         = -g

# Linux
ifeq ($(UNAME),Linux)
    LIBS        += -lusb-1.0 -lpthread
    HIDSRC      = hidapi/hid-libusb.c
endif

# Mac OS X
ifeq ($(UNAME),Darwin)
    LIBS        += -framework IOKit -framework CoreFoundation
    HIDSRC      = hidapi/hid-mac.c
endif

PROG_OBJS       = pic32prog.o target.o executive.o hid.o \
                  adapter-pickit2.o adapter-hidboot.o adapter-an1388.o

# Olimex ARM-USB-Tiny JTAG adapter: not finished yet.
CFLAGS         += -DUSE_MPSSE
PROG_OBJS      += adapter-mpsse.o
LIBS           += -L/opt/local/lib -lusb

all:            pic32prog

pic32prog:      $(PROG_OBJS)
		$(CC) $(LDFLAGS) -o $@ $(PROG_OBJS) $(LIBS)

hid.o:          $(HIDSRC)
		$(CC) $(CFLAGS) -c -o $@ $<

load:           demo1986ve91.srec
		pic32prog $<

adapter-mpsse:	adapter-mpsse.c
		$(CC) $(LDFLAGS) $(CFLAGS) -DSTANDALONE -o $@ adapter-mpsse.c $(LIBS)

pic32prog.po:	*.c
		xgettext --from-code=utf-8 --keyword=_ pic32prog.c target.c adapter-lpt.c -o $@

pic32prog-ru.mo: pic32prog-ru.po
		msgfmt -c -o $@ $<

pic32prog-ru-cp866.mo ru/LC_MESSAGES/pic32prog.mo: pic32prog-ru.po
		iconv -f utf-8 -t cp866 $< | sed 's/UTF-8/CP866/' | msgfmt -c -o $@ -
		cp pic32prog-ru-cp866.mo ru/LC_MESSAGES/pic32prog.mo

clean:
		rm -f *~ *.o core pic32prog adapter-mpsse pic32prog.po

install:	pic32prog #pic32prog-ru.mo
		install -c -s pic32prog /usr/local/bin/pic32prog
#		install -c -m 444 pic32prog-ru.mo /usr/local/share/locale/ru/LC_MESSAGES/pic32prog.mo
###
adapter-an1388.o: adapter-an1388.c adapter.h hidapi/hidapi.h pic32.h
adapter-hidboot.o: adapter-hidboot.c adapter.h hidapi/hidapi.h pic32.h
adapter-mpsse.o: adapter-mpsse.c adapter.h
adapter-pickit2.o: adapter-pickit2.c adapter.h pickit2.h pic32.h
executive.o: executive.c pic32.h
pic32prog.o: pic32prog.c target.h localize.h .svn/entries
target.o: target.c target.h adapter.h localize.h pic32.h
