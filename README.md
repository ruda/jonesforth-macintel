JonesForth MacIntel
===================

JonesForth is a Public Domain implementation of FORTH language/environment/machine. JonesForth MacIntel is the port of JonesForth to Macintosh Intel (32-bit).

How to build
------------

Use GCC in 32-bit model:

    $ gcc -m32 -nostdlib -static jonesforth-macintel.s -o jonesforth

But if you want to compile the interpreter with debug information:

    $ make jonesforth

This software is know to work on Snow Leopard, Lion and Mountain Lion.

Running FORTH
-------------

JonesForth requires extra FORTH definitions stored in `jonesforth.f`, so pass `jonesforth.f` and the standard input (STDIN) to the interpreter. Note: the interpreter don't accept parameters.

    $ cat jonesforth.f - | ./jonesforth 
    JONESFORTH VERSION 47 
    OK 

Or alternatively:

    $ ./run
    JONESFORTH VERSION 47 
    OK 

To exit from FORTH, type `BYE` command.
