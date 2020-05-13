all:
	nasm -f ELF64 crackme.asm -o crackme.o
	ld -o crackme -N --strip-all crackme.o
	rm crackme.o