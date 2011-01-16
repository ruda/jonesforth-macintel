JonesForth Macintel
===================

About
-----
This is the port of [JonesForth](http://www.annexia.org/forth) to Macintosh Intel (32-bit). JonesForth is a Public Domain implementation of [FORTH](http://www.forth.org/) language/environment/machine.

Compiling
---------
Use GCC in 32-bit model (-m32), like:

    $ gcc -m32 -nostdlib jonesforth-macintel.s -o jonesforth

If you want to compile with debug information, I recomend to use the makefile `jonesforth.mk`.

    $ make -f jonesforh.mk

Running
-------
Pass `jonesforth.f` which contains procedures written in FORTH with STDIN to read your input, to the interpreter. Note the interpreter don't accept parameters.

    $ cat jonesforth.f - | ./jonesforth 
    JONESFORTH VERSION 47 
    OK 

If you want to exit from the interpreter, the command is `BYE`.
   
License
-------
Public Domain.
