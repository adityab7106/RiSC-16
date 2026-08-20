CC = gcc
CFLAGS = -Wall -Wextra -O2

all: assembler_bin

assembler_bin: assembler/assembler.c
	$(CC) $(CFLAGS) -o assembler_bin assembler/assembler.c

upload: assembler_bin
	./assembler_bin program.s program.hex
	.venv/bin/python host/uploader.py program.hex


clean:
	rm -f assembler_bin *.hex

.PHONY: all clean upload
