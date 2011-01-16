all: jonesforth

jonesforth.o: jonesforth-macintel.s
	gcc -E jonesforth-macintel.s > jonesforth.s
	as -arch i386 -g jonesforth.s -o jonesforth.o

jonesforth: jonesforth.o
	ld -arch i386 jonesforth.o -o jonesforth

clean:
	rm -f jonesforth.o jonesforth.s jonesforth
