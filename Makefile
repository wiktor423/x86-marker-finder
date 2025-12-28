CC=gcc
ASM=nasm
CCOPT=-g -O0 -m32
NASMOPT=-f elf32 -g -F dwarf -w+all
CFLAGS=$(CCOPT)

all: marker_test

main.o: main.c
	$(CC) $(CFLAGS) -c $< -o $@

find_markers.o: find_markers.asm
	$(ASM) $(NASMOPT) $< -o $@

marker_test: main.o find_markers.o
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -f main.o find_markers.o marker_test