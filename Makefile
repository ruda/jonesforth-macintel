all: jonesforth

jonesforth: jonesforth-macintel.s
	gcc -E jonesforth-macintel.s > jonesforth.s
	as -arch i386 -g jonesforth.s -o jonesforth.o
	ld -arch i386 jonesforth.o -o jonesforth

test: jonesforth
	cat jonesforth.f test.f | ./jonesforth

run: jonesforth
	cat jonesforth.f - | ./jonesforth

clean:
	rm -f *~ jonesforth.o jonesforth.s jonesforth
