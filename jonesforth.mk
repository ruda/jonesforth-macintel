all: jones

jones.o: jonesforth-macintel.s
	gcc -E jonesforth-macintel.s > jones.s
	as -g jones.s -o jones.o

jones: jones.o
	ld jones.o -o jones

clean:
	rm -f jones.o jones.s jones
