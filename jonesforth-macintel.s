/*
 * jonesforth-macintel.s - jonesforth.s ported to Macintosh i386
 *
 * For more information about jonesforth.s, please visit
 *   http://www.annexia.org/forth
 *
 * Compile with gcc -m32 -nostdlib jonesforth-macintel.s -o jonesforth
 * Execute with cat jonesforth.f - | ./jonesforth
 *
 * This is also in Public Domain -- Ruda Moura <ruda.moura@gmail.com>
 */

#include <sys/syscall.h>

	.set JONES_VERSION,47

	.macro NEXT
	lodsl
	jmp *(%eax)
	.endm

	.macro PUSHRSP
	lea -4(%ebp),%ebp	// push reg on to return stack
	movl $0,(%ebp)
	.endm

	.macro POPRSP
	mov (%ebp),$0		// pop top of return stack to reg
	lea 4(%ebp),%ebp
	.endm

	.text
	.align 2
DOCOL:
	PUSHRSP %esi		// push %esi on to the return stack
	addl $4,%eax		// %eax points to codeword, so make
	movl %eax,%esi		// %esi point to first data word
	NEXT

	.text
	.globl start
start:
	cld
	mov %esp,var_SZ		// Save the initial data stack pointer in FORTH variable S0.
	mov $return_stack_top,%ebp // Initialise the return stack.
	mov $cold_start,%esi	// Initialise interpreter.
	NEXT			// Run interpreter!

	.const_data
	.align 2
cold_start:			// High-level code without a codeword.
	.long QUIT

	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f	// length mask

	.macro defword
	.const_data
	.align 2
	.globl name_$3
name_$3 :
	.long $4		// link
	.byte $2+$1		// flags + length byte
	.ascii $0		// the name
	.align 2		// padding to next 4 byte boundary
	.globl $3
$3 :
	.long DOCOL		// codeword - the interpreter
	// list of word pointers follow
	.endm

	.macro defcode
	.const_data
	.align 2
	.globl name_$3
name_$3 :
	.long $4		// link
	.byte $2+$1		// flags + length byte
	.ascii $0		// the name
	.align 2		// padding to next 4 byte boundary
	.globl $3
$3 :
	.long code_$3	// codeword
	.text
	.align 2
	.globl code_$3
code_$3 :			// assembler code follows
	.endm

	defcode "DROP",4,0,DROP,0
	pop %eax		// drop top of stack
	NEXT

	defcode "SWAP",4,0,SWAP,name_DROP
	pop %eax		// swap top two elements on stack
	pop %ebx
	push %eax
	push %ebx
	NEXT

	defcode "DUP",3,0,DUP,name_SWAP
	mov (%esp),%eax		// duplicate top of stack
	push %eax
	NEXT

	defcode "OVER",4,0,OVER,name_DUP
	mov 4(%esp),%eax	// get the second element of stack
	push %eax		// and push it on top
	NEXT

	defcode "ROT",3,0,ROT,name_OVER
	pop %eax
	pop %ebx
	pop %ecx
	push %ebx
	push %eax
	push %ecx
	NEXT

	defcode "-ROT",4,0,NROT,name_ROT
	pop %eax
	pop %ebx
	pop %ecx
	push %eax
	push %ecx
	push %ebx
	NEXT

	defcode "2DROP",5,0,TWODROP,name_NROT // drop top two elements of stack
	pop %eax
	pop %eax
	NEXT

	defcode "2DUP",4,0,TWODUP,name_TWODROP // duplicate top two elements of stack
	mov (%esp),%eax
	mov 4(%esp),%ebx
	push %ebx
	push %eax
	NEXT

	defcode "2SWAP",5,0,TWOSWAP,name_TWODUP // swap top two pairs of elements of stack
	pop %eax
	pop %ebx
	pop %ecx
	pop %edx
	push %ebx
	push %eax
	push %edx
	push %ecx
	NEXT

	defcode "?DUP",4,0,QDUP,name_TWOSWAP	// duplicate top of stack if non-zero
	movl (%esp),%eax
	test %eax,%eax
	jz 1f
	push %eax
1:	NEXT

	defcode "1+",2,0,INCR,name_QDUP
	incl (%esp)		// increment top of stack
	NEXT

	defcode "1-",2,0,DECR,name_INCR
	decl (%esp)		// decrement top of stack
	NEXT

	defcode "4+",2,0,INCR4,name_DECR
	addl $4,(%esp)		// add 4 to top of stack
	NEXT

	defcode "4-",2,0,DECR4,name_INCR4
	subl $4,(%esp)		// subtract 4 from top of stack
	NEXT

	defcode "+",1,0,ADD,name_DECR4
	pop %eax		// get top of stack
	addl %eax,(%esp)	// and add it to next word on stack
	NEXT

	defcode "-",1,0,SUB,name_ADD
	pop %eax		// get top of stack
	subl %eax,(%esp)	// and subtract it from next word on stack
	NEXT

	defcode "*",1,0,MUL,name_SUB
	pop %eax
	pop %ebx
	imull %ebx,%eax
	push %eax		// ignore overflow
	NEXT

	defcode "/MOD",4,0,DIVMOD,name_MUL
	xor %edx,%edx
	pop %ebx
	pop %eax
	idivl %ebx
	push %edx		// push remainder
	push %eax		// push quotient
	NEXT

	defcode "=",1,0,EQU,name_DIVMOD	// top two words are equal?
	pop %eax
	pop %ebx
	cmp %ebx,%eax
	sete %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "<>",2,0,NEQU,name_EQU	// top two words are not equal?
	pop %eax
	pop %ebx
	cmp %ebx,%eax
	setne %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "<",1,0,LT,name_NEQU
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setl %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode ">",1,0,GT,name_LT
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setg %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "<=",2,0,LE,name_GT
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setle %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode ">=",2,0,GE,name_LE
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setge %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0=",2,0,ZEQU,name_GE	// top of stack equals 0?
	pop %eax
	test %eax,%eax
	setz %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0<>",3,0,ZNEQU,name_ZEQU	// top of stack not 0?
	pop %eax
	test %eax,%eax
	setnz %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0<",2,0,ZLT,name_ZNEQU	// comparisons with 0
	pop %eax
	test %eax,%eax
	setl %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0>",2,0,ZGT,name_ZLT
	pop %eax
	test %eax,%eax
	setg %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0<=",3,0,ZLE,name_ZGT
	pop %eax
	test %eax,%eax
	setle %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0>=",3,0,ZGE,name_ZLE
	pop %eax
	test %eax,%eax
	setge %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "AND",3,0,AND,name_ZGE	// bitwise AND
	pop %eax
	andl %eax,(%esp)
	NEXT

	defcode "OR",2,0,OR,name_AND	// bitwise OR
	pop %eax
	orl %eax,(%esp)
	NEXT

	defcode "XOR",3,0,XOR,name_OR	// bitwise XOR
	pop %eax
	xorl %eax,(%esp)
	NEXT

	defcode "INVERT",6,0,INVERT,name_XOR // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
	notl (%esp)
	NEXT

	defcode "EXIT",4,0,EXIT,name_INVERT
	POPRSP %esi		// pop return stack into %esi
	NEXT

	defcode "LIT",3,0,LIT,name_EXIT
	// %esi points to the next command, but in this case it points to the next
	// literal 32 bit integer.  Get that literal into %eax and increment %esi.
	// On x86, it's a convenient single byte instruction!  (cf. NEXT macro)
	lodsl
	push %eax		// push the literal number on to stack
	NEXT

	defcode "!",1,0,STORE,name_LIT
	pop %ebx		// address to store at
	pop %eax		// data to store there
	mov %eax,(%ebx)		// store it
	NEXT

	defcode "@",1,0,FETCH,name_STORE
	pop %ebx		// address to fetch
	mov (%ebx),%eax		// fetch it
	push %eax		// push value onto stack
	NEXT

	defcode "+!",2,0,ADDSTORE,name_FETCH
	pop %ebx		// address
	pop %eax		// the amount to add
	addl %eax,(%ebx)	// add it
	NEXT

	defcode "-!",2,0,SUBSTORE,name_ADDSTORE
	pop %ebx		// address
	pop %eax		// the amount to subtract
	subl %eax,(%ebx)	// add it
	NEXT

	defcode "C!",2,0,STOREBYTE,name_SUBSTORE
	pop %ebx		// address to store at
	pop %eax		// data to store there
	movb %al,(%ebx)		// store it
	NEXT

	defcode "C@",2,0,FETCHBYTE,name_STOREBYTE
	pop %ebx		// address to fetch
	xor %eax,%eax
	movb (%ebx),%al		// fetch it
	push %eax		// push value onto stack
	NEXT

	defcode "C@C!",4,0,CCOPY,name_FETCHBYTE
	movl 4(%esp),%ebx	// source address
	movb (%ebx),%al		// get source character
	pop %edi		// destination address
	stosb			// copy to destination
	push %edi		// increment destination address
	incl 4(%esp)		// increment source address
	NEXT

	defcode "CMOVE",5,0,CMOVE,name_CCOPY
	mov %esi,%edx		// preserve %esi
	pop %ecx		// length
	pop %edi		// destination address
	pop %esi		// source address
	rep movsb		// copy source to destination
	mov %edx,%esi		// restore %esi
	NEXT

	.macro defvar
	defcode $0,$1,$2,$3,$4
	push $var_$3
	NEXT
	.data
	.align 2
var_$3 :
	.long $5
	.endm

	defvar "STATE",5,0,STATE,name_CMOVE,0
	defvar "HERE",4,0,HERE,name_STATE,user_defs_start
	defvar "LATEST",6,0,LATEST,name_HERE,name_SYSCALL // SYSCALL must be last in built-in dictionary
	defvar "S0",2,0,SZ,name_LATEST,0
	defvar "BASE",4,0,BASE,name_SZ,10


	.macro defconst
	defcode $0,$1,$2,$3,$4
	pushl $5
	NEXT
	.endm

	defconst "VERSION",7,0,VERSION,name_BASE,$JONES_VERSION
	defconst "R0",2,0,RZ,name_VERSION,$return_stack_top
	defconst "DOCOL",5,0,__DOCOL,name_RZ,$DOCOL
	defconst "F_IMMED",7,0,__F_IMMED,name___DOCOL,$F_IMMED
	defconst "F_HIDDEN",8,0,__F_HIDDEN,name___F_IMMED,$F_HIDDEN
	defconst "F_LENMASK",9,0,__F_LENMASK,name___F_HIDDEN,$F_LENMASK

	defconst "SYS_EXIT",8,0,SYS_EXIT,name___F_LENMASK,$SYS_exit
	defconst "SYS_OPEN",8,0,SYS_OPEN,name_SYS_EXIT,$SYS_open
	defconst "SYS_CLOSE",9,0,SYS_CLOSE,name_SYS_OPEN,$SYS_close
	defconst "SYS_READ",8,0,SYS_READ,name_SYS_CLOSE,$SYS_read
	defconst "SYS_WRITE",9,0,SYS_WRITE,name_SYS_READ,$SYS_write

	defconst "O_RDONLY",8,0,__O_RDONLY,name_SYS_WRITE,$0
	defconst "O_WRONLY",8,0,__O_WRONLY,name___O_RDONLY,$1
	defconst "O_RDWR",6,0,__O_RDWR,name___O_WRONLY,$2
	defconst "O_CREAT",7,0,__O_CREAT,name___O_RDWR,$0100
	defconst "O_EXCL",6,0,__O_EXCL,name___O_CREAT,$0200
	defconst "O_TRUNC",7,0,__O_TRUNC,name___O_EXCL,$01000
	defconst "O_APPEND",8,0,__O_APPEND,name___O_TRUNC,$02000
	defconst "O_NONBLOCK",10,0,__O_NONBLOCK,name___O_APPEND,$04000

	defcode ">R",2,0,TOR,name___O_NONBLOCK
	pop %eax		// pop parameter stack into %eax
	PUSHRSP %eax		// push it on to the return stack
	NEXT

	defcode "R>",2,0,FROMR,name_TOR
	POPRSP %eax		// pop return stack on to %eax
	push %eax		// and push on to parameter stack
	NEXT

	defcode "RSP@",4,0,RSPFETCH,name_FROMR
	push %ebp
	NEXT

	defcode "RSP!",4,0,RSPSTORE,name_RSPFETCH
	pop %ebp
	NEXT

	defcode "RDROP",5,0,RDROP,name_RSPSTORE
	addl $4,%ebp		// pop return stack and throw away
	NEXT

	defcode "DSP@",4,0,DSPFETCH,name_RDROP
	mov %esp,%eax
	push %eax
	NEXT

	defcode "DSP!",4,0,DSPSTORE,name_DSPFETCH
	pop %esp
	NEXT

	defcode "KEY",3,0,KEY,name_DSPSTORE
	call _KEY
	push %eax		// push return value on stack
	NEXT
_KEY:
	mov (currkey),%ebx
	cmp (bufftop),%ebx
	jge 1f			// exhausted the input buffer?
	xor %eax,%eax
	mov (%ebx),%al		// get next key from input buffer
	inc %ebx
	mov %ebx,(currkey)	// increment currkey
	ret

1:	// Out of input; use read(2) to fetch more input from stdin.
	xor %ebx,%ebx		// 1st param: stdin
	mov $buffer,%ecx	// 2nd param: buffer
	mov %ecx,currkey
	mov $BUFFER_SIZE,%edx	// 3rd param: max length
	push %edx
	push %ecx
	push %ebx
	mov $SYS_read,%eax	// syscall: read
	call _syscall
	addl $12,%esp
	test %eax,%eax		// If %eax <= 0, then exit.
	jbe 2f
	addl %eax,%ecx		// buffer+%eax = bufftop
	mov %ecx,bufftop
	jmp _KEY

2:	// Error or end of input: exit the program.
	push $0			// 1st param: rval
	mov $SYS_exit,%eax	// syscall: exit
	call _syscall

	.data
	.align 2
currkey:
	.long buffer		// Current place in input buffer (next character to read).
bufftop:
	.long buffer		// Last valid data in input buffer + 1.

	defcode "EMIT",4,0,EMIT,name_KEY
	pop %eax
	call _EMIT
	NEXT
_EMIT:
	mov $1,%ebx		// 1st param: stdout

	// write needs the address of the byte to write
	mov %al,emit_scratch
	mov $emit_scratch,%ecx	// 2nd param: address

	mov $1,%edx		// 3rd param: nbytes = 1

	push %edx
	push %ecx
	push %ebx
	mov $SYS_write,%eax	// write syscall
	call _syscall
	addl $12,%esp
	ret

	.data			// NB: easier to fit in the .data section
emit_scratch:
	.space 1		// scratch used by EMIT

	defcode "WORD",4,0,WORD,name_EMIT
	call _WORD
	push %edi		// push base address
	push %ecx		// push length
	NEXT

_WORD:
	/* Search for first non-blank character.  Also skip \ comments. */
1:
	call _KEY		// get next key, returned in %eax
	cmpb $92,%al		// start of a comment?
	je 3f			// if so, skip the comment
	cmpb $32,%al
	jbe 1b			// if so, keep looking

	/* Search for the end of the word, storing chars as we go. */
	mov $word_buffer,%edi	// pointer to return buffer
2:
	stosb			// add character to return buffer
	call _KEY		// get next key, returned in %al
	cmpb $32,%al		// is blank?
	ja 2b			// if not, keep looping

	/* Return the word (well, the static buffer) and length. */
	sub $word_buffer,%edi
	mov %edi,%ecx		// return length of the word
	mov $word_buffer,%edi	// return address of the word
	ret

	/* Code to skip \ comments to end of the current line. */
3:
	call _KEY
	cmpb $10,%al		// end of line yet?
	jne 3b
	jmp 1b

	.data			// NB: easier to fit in the .data section
	// A static buffer where WORD returns.  Subsequent calls
	// overwrite this buffer.  Maximum word length is 32 chars.
	.align 2
word_buffer:
	.space 64

	defcode "NUMBER",6,0,NUMBER,name_WORD
	pop %ecx		// length of string
	pop %edi		// start address of string
	call _NUMBER
	push %eax		// parsed number
	push %ecx		// number of unparsed characters (0 = no error)
	NEXT

_NUMBER:
	xor %eax,%eax
	xor %ebx,%ebx

	test %ecx,%ecx		// trying to parse a zero-length string is an error, but will return 0.
	jz 5f

	movl var_BASE,%edx	// get BASE (in %dl)

	// Check if first character is '-'.
	movb (%edi),%bl		// %bl = first character in string
	inc %edi
	push %eax		// push 0 on stack
	cmpb $45,%bl		// negative number?
	jnz 2f
	pop %eax
	push %ebx		// push <> 0 on stack, indicating negative
	dec %ecx
	jnz 1f
	pop %ebx		// error: string is only '-'.
	movl $1,%ecx
	ret

	// Loop reading digits.
1:	imull %edx,%eax		// %eax *= BASE
	movb (%edi),%bl		// %bl = next character in string
	inc %edi

	// Convert 0-9, A-Z to a number 0-35.
2:	subb $48,%bl		// < '0'?
	jb 4f
	cmp $10,%bl		// <= '9'?
	jb 3f
	subb $17,%bl		// < 'A'? (17 is 'A'-'0')
	jb 4f
	addb $10,%bl

3:	cmp %dl,%bl		// >= BASE?
	jge 4f

	// OK, so add it to %eax and loop.
	add %ebx,%eax
	dec %ecx
	jnz 1b

	// Negate the result if first character was '-' (saved on the stack).
4:	pop %ebx
	test %ebx,%ebx
	jz 5f
	neg %eax

5:	ret

	defcode "FIND",4,0,FIND,name_NUMBER
	pop %ecx		// %ecx = length
	pop %edi		// %edi = address
	call _FIND
	push %eax		// %eax = address of dictionary entry (or NULL)
	NEXT

_FIND:
	push %esi		// Save %esi so we can use it in string comparison.

	// Now we start searching backwards through the dictionary for this word.
	mov var_LATEST,%edx	// LATEST points to name header of the latest word in the dictionary
1:	test %edx,%edx		// NULL pointer?  (end of the linked list)
	je 4f

	// Compare the length expected and the length of the word.
	// Note that if the F_HIDDEN flag is set on the word, then by a bit of trickery
	// this won't pick the word (the length will appear to be wrong).
	xor %eax,%eax
	movb 4(%edx),%al	// %al = flags+length field
	andb $(F_HIDDEN|F_LENMASK),%al // %al = name length
	cmpb %cl,%al		// Length is the same?
	jne 2f

	// Compare the strings in detail.
	push %ecx		// Save the length
	push %edi		// Save the address (repe cmpsb will move this pointer)
	lea 5(%edx),%esi	// Dictionary string we are checking against.
	repe cmpsb		// Compare the strings.
	pop %edi
	pop %ecx
	jne 2f			// Not the same.

	// The strings are the same - return the header pointer in %eax
	pop %esi
	mov %edx,%eax
	ret
2:	mov (%edx),%edx		// Move back through the link field to the previous word
	jmp 1b			// .. and loop.

4:	// Not found.
	pop %esi
	xor %eax,%eax		// Return zero to indicate not found.
	ret

	defcode ">CFA",4,0,TCFA,name_FIND
	pop %edi
	call _TCFA
	push %edi
	NEXT
_TCFA:
	xor %eax,%eax
	add $4,%edi		// Skip link pointer.
	movb (%edi),%al		// Load flags+len into %al.
	inc %edi		// Skip flags+len byte.
	andb $F_LENMASK,%al	// Just the length, not the flags.
	add %eax,%edi		// Skip the name.
	addl $3,%edi		// The codeword is 4-byte aligned.
	andl $~3,%edi
	ret

	defword ">DFA",4,0,TDFA,name_TCFA
	.long TCFA		// >CFA		(get code field address)
	.long INCR4		// 4+		(add 4 to it to get to next word)
	.long EXIT		// EXIT		(return from FORTH word)

	defcode "CREATE",6,0,CREATE,name_TDFA

	// Get the name length and address.
	pop %ecx		// %ecx = length
	pop %ebx		// %ebx = address of name

	// Link pointer.
	movl var_HERE,%edi	// %edi is the address of the header
	movl var_LATEST,%eax	// Get link pointer
	stosl			// and store it in the header.

	// Length byte and the word itself.
	mov %cl,%al		// Get the length.
	stosb			// Store the length/flags byte.
	push %esi
	mov %ebx,%esi		// %esi = word
	rep movsb		// Copy the word
	pop %esi
	addl $3,%edi		// Align to next 4 byte boundary.
	andl $~3,%edi

	// Update LATEST and HERE.
	movl var_HERE,%eax
	movl %eax,var_LATEST
	movl %edi,var_HERE
	NEXT

	defcode "\054",1,0,COMMA,name_CREATE
	pop %eax		// Code pointer to store.
	call _COMMA
	NEXT
_COMMA:
	movl var_HERE,%edi	// HERE
	stosl			// Store it.
	movl %edi,var_HERE	// Update HERE (incremented)
	ret

	defcode "[",1,F_IMMED,LBRAC,name_COMMA
	xor %eax,%eax
	movl %eax,var_STATE	// Set STATE to 0.
	NEXT

	defcode "]",1,0,RBRAC,name_LBRAC
	movl $1,var_STATE	// Set STATE to 1.
	NEXT

	defword ":",1,0,COLON,name_RBRAC
	.long WORD		// Get the name of the new word
	.long CREATE		// CREATE the dictionary entry / header
	.long LIT, DOCOL, COMMA	// Append DOCOL  (the codeword).
	.long LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition).
	.long RBRAC		// Go into compile mode.
	.long EXIT		// Return from the function.

	defword "\073",1,F_IMMED,SEMICOLON,name_COLON
	.long LIT, EXIT, COMMA	// Append EXIT (so the word will return).
	.long LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition).
	.long LBRAC		// Go back to IMMEDIATE mode.
	.long EXIT		// Return from the function.

	defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE,name_SEMICOLON
	movl var_LATEST,%edi	// LATEST word.
	addl $4,%edi		// Point to name/flags byte.
	xorb $F_IMMED,(%edi)	// Toggle the IMMED bit.
	NEXT

	defcode "HIDDEN",6,0,HIDDEN,name_IMMEDIATE
	pop %edi		// Dictionary entry.
	addl $4,%edi		// Point to name/flags byte.
	xorb $F_HIDDEN,(%edi)	// Toggle the HIDDEN bit.
	NEXT

	defword "HIDE",4,0,HIDE,name_HIDDEN
	.long WORD		// Get the word (after HIDE).
	.long FIND		// Look up in the dictionary.
	.long HIDDEN		// Set F_HIDDEN flag.
	.long EXIT		// Return.

	defcode "'",1,0,TICK,name_HIDE
	lodsl			// Get the address of the next word and skip it.
	pushl %eax		// Push it on the stack.
	NEXT

	defcode "BRANCH",6,0,BRANCH,name_TICK
	add (%esi),%esi		// add the offset to the instruction pointer
	NEXT

	defcode "0BRANCH",7,0,ZBRANCH,name_BRANCH
	pop %eax
	test %eax,%eax		// top of stack is zero?
	jz code_BRANCH		// if so, jump back to the branch function above
	lodsl			// otherwise we need to skip the offset
	NEXT

	defcode "LITSTRING",9,0,LITSTRING,name_ZBRANCH
	lodsl			// get the length of the string
	push %esi		// push the address of the start of the string
	push %eax		// push it on the stack
	addl %eax,%esi		// skip past the string
 	addl $3,%esi		// but round up to next 4 byte boundary
	andl $~3,%esi
	NEXT

	defcode "TELL",4,0,TELL,name_LITSTRING
	mov $1,%ebx		// 1st param: stdout
	pop %edx		// 3rd param: length of string
	pop %ecx		// 2nd param: address of string
	mov $SYS_write,%eax	// write syscall
	push %edx
	push %ecx
	push %ebx
	call _syscall
	addl $12,%esp
	NEXT

	// QUIT must not return (ie. must not call EXIT).
	defword "QUIT",4,0,QUIT,name_TELL
	.long RZ,RSPSTORE	// R0 RSP!, clear the return stack
	.long INTERPRET		// interpret the next word
	.long BRANCH,-8		// and loop (indefinitely)

	defcode "INTERPRET",9,0,INTERPRET,name_QUIT
	call _WORD		// Returns %ecx = length, %edi = pointer to word.

	// Is it in the dictionary?
	xor %eax,%eax
	movl %eax,interpret_is_lit // Not a literal number (not yet anyway ...)
	call _FIND		// Returns %eax = pointer to header or 0 if not found.
	test %eax,%eax		// Found?
	jz 1f

	// In the dictionary.  Is it an IMMEDIATE codeword?
	mov %eax,%edi		// %edi = dictionary entry
	movb 4(%edi),%al	// Get name+flags.
	push %ax		// Just save it for now.
	call _TCFA		// Convert dictionary entry (in %edi) to codeword pointer.
	pop %ax
	andb $F_IMMED,%al	// Is IMMED flag set?
	mov %edi,%eax
	jnz 4f			// If IMMED, jump straight to executing.

	jmp 2f

1:	// Not in the dictionary (not a word) so assume it's a literal number.
	incl interpret_is_lit
	call _NUMBER		// Returns the parsed number in %eax, %ecx > 0 if error
	test %ecx,%ecx
	jnz 6f
	mov %eax,%ebx
	mov $LIT,%eax		// The word is LIT

2:	// Are we compiling or executing?
	movl var_STATE,%edx
	test %edx,%edx
	jz 4f			// Jump if executing.

	// Compiling - just append the word to the current dictionary definition.
	call _COMMA
	mov interpret_is_lit,%ecx // Was it a literal?
	test %ecx,%ecx
	jz 3f
	mov %ebx,%eax		// Yes, so LIT is followed by a number.
	call _COMMA
3:	NEXT

4:	// Executing - run it!
	mov interpret_is_lit,%ecx // Literal?
	test %ecx,%ecx		// Literal?
	jnz 5f

	// Not a literal, execute it now.  This never returns, but the codeword will
	// eventually call NEXT which will reenter the loop in QUIT.
	jmp *(%eax)

5:	// Executing a literal, which means push it on the stack.
	push %ebx
	NEXT

6:	// Parse error (not a known word or a number in the current BASE).
	// Print an error message followed by up to 40 characters of context.
	mov $2,%ebx		// 1st param: stderr
	mov $errmsg,%ecx	// 2nd param: error message
	mov $errmsgend-errmsg,%edx // 3rd param: length of string
	push %edx
	push %ecx
	push %ebx
	mov $SYS_write,%eax	// write syscall
	call _syscall
	addl $12,%esp

	mov (currkey),%ecx	// the error occurred just before currkey position
	mov %ecx,%edx
	sub $buffer,%edx	// %edx = currkey - buffer (length in buffer before currkey)
	cmp $40,%edx		// if > 40, then print only 40 characters
	jle 7f
	mov $40,%edx
7:	sub %edx,%ecx		// %ecx = start of area to print, %edx = length
	push %edx
	push %ecx
	push %ebx
	mov $SYS_write,%eax	// write syscall
	call _syscall
	addl $12,%esp

	mov $errmsgnl,%ecx	// newline
	mov $1,%edx
	push %edx
	push %ecx
	push %ebx	
	mov $SYS_write,%eax	// write syscall
	call _syscall
	addl $12,%esp

	NEXT

	.data
errmsg: .ascii "PARSE ERROR: "
errmsgend:
errmsgnl: .ascii "\n"

	.data			// NB: easier to fit in the .data section
	.align 2
interpret_is_lit:
	.long 0			// Flag used to record if reading a literal

	defcode "CHAR",4,0,CHAR,name_INTERPRET
	call _WORD		// Returns %ecx = length, %edi = pointer to word.
	xor %eax,%eax
	movb (%edi),%al		// Get the first character of the word.
	push %eax		// Push it onto the stack.
	NEXT

	defcode "EXECUTE",7,0,EXECUTE,name_CHAR
	pop %eax		// Get xt into %eax
	jmp *(%eax)		// and jump to it.
				// After xt runs its NEXT will continue executing the current word.

	defcode "SYSCALL",7,0,SYSCALL,name_EXECUTE
	pop %eax		// System call number (see <asm/unistd.h>)
	call _syscall
	push %eax		// Result (negative for -errno)
	NEXT

	.text
_syscall:
	int $0x80
	ret

	.set RETURN_STACK_SIZE,8192
	.set BUFFER_SIZE,4096
	.set USER_DEFS_SIZE,65536

	.data
/* FORTH return stack. */
	.align 2
return_stack:
	.space RETURN_STACK_SIZE
return_stack_top:		// Initial top of return stack.

/* This is used as a temporary input buffer when reading from files or the terminal. */
	.align 2
buffer:
	.space BUFFER_SIZE

	.align 2
user_defs_start:
	.space USER_DEFS_SIZE
