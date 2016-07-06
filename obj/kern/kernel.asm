
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 19 10 f0 	movl   $0xf0101980,(%esp)
f0100055:	e8 2c 09 00 00       	call   f0100986 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 24 07 00 00       	call   f01007ab <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 19 10 f0 	movl   $0xf010199c,(%esp)
f0100092:	e8 ef 08 00 00       	call   f0100986 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 12 14 00 00       	call   f01014d7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 19 10 f0 	movl   $0xf01019b7,(%esp)
f01000d9:	e8 a8 08 00 00       	call   f0100986 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 14 07 00 00       	call   f010080a <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 19 10 f0 	movl   $0xf01019d2,(%esp)
f010012c:	e8 55 08 00 00       	call   f0100986 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 16 08 00 00       	call   f0100953 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100144:	e8 3d 08 00 00       	call   f0100986 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 b5 06 00 00       	call   f010080a <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 19 10 f0 	movl   $0xf01019ea,(%esp)
f0100176:	e8 0b 08 00 00       	call   f0100986 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 c9 07 00 00       	call   f0100953 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100191:	e8 f0 07 00 00       	call   f0100986 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 60 1a 10 f0 	movzbl -0xfefe5a0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 40 1a 10 f0 	mov    -0xfefe5c0(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 04 1a 10 f0 	movl   $0xf0101a04,(%esp)
f01002e9:	e8 98 06 00 00       	call   f0100986 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 96 10 00 00       	call   f0101524 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 10 1a 10 f0 	movl   $0xf0101a10,(%esp)
f0100644:	e8 3d 03 00 00       	call   f0100986 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 60 1c 10 	movl   $0xf0101c60,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 7e 1c 10 	movl   $0xf0101c7e,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 83 1c 10 f0 	movl   $0xf0101c83,(%esp)
f010069d:	e8 e4 02 00 00       	call   f0100986 <cprintf>
f01006a2:	c7 44 24 08 18 1d 10 	movl   $0xf0101d18,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 8c 1c 10 	movl   $0xf0101c8c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 83 1c 10 f0 	movl   $0xf0101c83,(%esp)
f01006b9:	e8 c8 02 00 00       	call   f0100986 <cprintf>
f01006be:	c7 44 24 08 40 1d 10 	movl   $0xf0101d40,0x8(%esp)
f01006c5:	f0 
f01006c6:	c7 44 24 04 95 1c 10 	movl   $0xf0101c95,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 83 1c 10 f0 	movl   $0xf0101c83,(%esp)
f01006d5:	e8 ac 02 00 00       	call   f0100986 <cprintf>
	return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006e7:	c7 04 24 9f 1c 10 f0 	movl   $0xf0101c9f,(%esp)
f01006ee:	e8 93 02 00 00       	call   f0100986 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006fa:	00 
f01006fb:	c7 04 24 64 1d 10 f0 	movl   $0xf0101d64,(%esp)
f0100702:	e8 7f 02 00 00       	call   f0100986 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f010071e:	e8 63 02 00 00       	call   f0100986 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 67 19 10 	movl   $0x101967,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 67 19 10 	movl   $0xf0101967,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 b0 1d 10 f0 	movl   $0xf0101db0,(%esp)
f010073a:	e8 47 02 00 00       	call   f0100986 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 d4 1d 10 f0 	movl   $0xf0101dd4,(%esp)
f0100756:	e8 2b 02 00 00       	call   f0100986 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f0100772:	e8 0f 02 00 00       	call   f0100986 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100777:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010077c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100781:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100786:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010078c:	85 c0                	test   %eax,%eax
f010078e:	0f 48 c2             	cmovs  %edx,%eax
f0100791:	c1 f8 0a             	sar    $0xa,%eax
f0100794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100798:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f010079f:	e8 e2 01 00 00       	call   f0100986 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
f01007ae:	56                   	push   %esi
f01007af:	53                   	push   %ebx
f01007b0:	83 ec 10             	sub    $0x10,%esp
	// Your code here.
	unsigned int *ebp = (unsigned int *)read_ebp();
f01007b3:	89 ee                	mov    %ebp,%esi
/***************************MY CODE****************************/
static inline unsigned int * 
dump_stack(unsigned int *ebp)
{
	unsigned int i = 0;
	cprintf("ebp: %08x ,eip: %08x ,args:",ebp,*(ebp + 1));
f01007b5:	8b 46 04             	mov    0x4(%esi),%eax
f01007b8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007bc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c0:	c7 04 24 b8 1c 10 f0 	movl   $0xf0101cb8,(%esp)
f01007c7:	e8 ba 01 00 00       	call   f0100986 <cprintf>
	for(i = 2;i < 7 ;i++)
f01007cc:	bb 02 00 00 00       	mov    $0x2,%ebx
	  cprintf("%08x ",*(ebp + i));
f01007d1:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d8:	c7 04 24 d4 1c 10 f0 	movl   $0xf0101cd4,(%esp)
f01007df:	e8 a2 01 00 00       	call   f0100986 <cprintf>
static inline unsigned int * 
dump_stack(unsigned int *ebp)
{
	unsigned int i = 0;
	cprintf("ebp: %08x ,eip: %08x ,args:",ebp,*(ebp + 1));
	for(i = 2;i < 7 ;i++)
f01007e4:	83 c3 01             	add    $0x1,%ebx
f01007e7:	83 fb 07             	cmp    $0x7,%ebx
f01007ea:	75 e5                	jne    f01007d1 <mon_backtrace+0x26>
	  cprintf("%08x ",*(ebp + i));

	cprintf("\n");
f01007ec:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f01007f3:	e8 8e 01 00 00       	call   f0100986 <cprintf>
	return (unsigned int*)*ebp;
f01007f8:	8b 36                	mov    (%esi),%esi
	unsigned int *ebp = (unsigned int *)read_ebp();

	do
	{
		ebp = dump_stack(ebp);
	}while(ebp);
f01007fa:	85 f6                	test   %esi,%esi
f01007fc:	75 b7                	jne    f01007b5 <mon_backtrace+0xa>

	return 0;
}
f01007fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100803:	83 c4 10             	add    $0x10,%esp
f0100806:	5b                   	pop    %ebx
f0100807:	5e                   	pop    %esi
f0100808:	5d                   	pop    %ebp
f0100809:	c3                   	ret    

f010080a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010080a:	55                   	push   %ebp
f010080b:	89 e5                	mov    %esp,%ebp
f010080d:	57                   	push   %edi
f010080e:	56                   	push   %esi
f010080f:	53                   	push   %ebx
f0100810:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100813:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f010081a:	e8 67 01 00 00       	call   f0100986 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081f:	c7 04 24 6c 1e 10 f0 	movl   $0xf0101e6c,(%esp)
f0100826:	e8 5b 01 00 00       	call   f0100986 <cprintf>


	while (1) {
		buf = readline("K> ");
f010082b:	c7 04 24 da 1c 10 f0 	movl   $0xf0101cda,(%esp)
f0100832:	e8 49 0a 00 00       	call   f0101280 <readline>
f0100837:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100839:	85 c0                	test   %eax,%eax
f010083b:	74 ee                	je     f010082b <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010083d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100844:	be 00 00 00 00       	mov    $0x0,%esi
f0100849:	eb 0a                	jmp    f0100855 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084b:	c6 03 00             	movb   $0x0,(%ebx)
f010084e:	89 f7                	mov    %esi,%edi
f0100850:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100853:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100855:	0f b6 03             	movzbl (%ebx),%eax
f0100858:	84 c0                	test   %al,%al
f010085a:	74 63                	je     f01008bf <monitor+0xb5>
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100863:	c7 04 24 de 1c 10 f0 	movl   $0xf0101cde,(%esp)
f010086a:	e8 2b 0c 00 00       	call   f010149a <strchr>
f010086f:	85 c0                	test   %eax,%eax
f0100871:	75 d8                	jne    f010084b <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100873:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100876:	74 47                	je     f01008bf <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100878:	83 fe 0f             	cmp    $0xf,%esi
f010087b:	75 16                	jne    f0100893 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010087d:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100884:	00 
f0100885:	c7 04 24 e3 1c 10 f0 	movl   $0xf0101ce3,(%esp)
f010088c:	e8 f5 00 00 00       	call   f0100986 <cprintf>
f0100891:	eb 98                	jmp    f010082b <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100893:	8d 7e 01             	lea    0x1(%esi),%edi
f0100896:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010089a:	eb 03                	jmp    f010089f <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010089c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010089f:	0f b6 03             	movzbl (%ebx),%eax
f01008a2:	84 c0                	test   %al,%al
f01008a4:	74 ad                	je     f0100853 <monitor+0x49>
f01008a6:	0f be c0             	movsbl %al,%eax
f01008a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ad:	c7 04 24 de 1c 10 f0 	movl   $0xf0101cde,(%esp)
f01008b4:	e8 e1 0b 00 00       	call   f010149a <strchr>
f01008b9:	85 c0                	test   %eax,%eax
f01008bb:	74 df                	je     f010089c <monitor+0x92>
f01008bd:	eb 94                	jmp    f0100853 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008bf:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c7:	85 f6                	test   %esi,%esi
f01008c9:	0f 84 5c ff ff ff    	je     f010082b <monitor+0x21>
f01008cf:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008d4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d7:	8b 04 85 a0 1e 10 f0 	mov    -0xfefe160(,%eax,4),%eax
f01008de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008e5:	89 04 24             	mov    %eax,(%esp)
f01008e8:	e8 4f 0b 00 00       	call   f010143c <strcmp>
f01008ed:	85 c0                	test   %eax,%eax
f01008ef:	75 24                	jne    f0100915 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008f1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f4:	8b 55 08             	mov    0x8(%ebp),%edx
f01008f7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008fb:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008fe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100902:	89 34 24             	mov    %esi,(%esp)
f0100905:	ff 14 85 a8 1e 10 f0 	call   *-0xfefe158(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010090c:	85 c0                	test   %eax,%eax
f010090e:	78 25                	js     f0100935 <monitor+0x12b>
f0100910:	e9 16 ff ff ff       	jmp    f010082b <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100915:	83 c3 01             	add    $0x1,%ebx
f0100918:	83 fb 03             	cmp    $0x3,%ebx
f010091b:	75 b7                	jne    f01008d4 <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010091d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100920:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100924:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f010092b:	e8 56 00 00 00       	call   f0100986 <cprintf>
f0100930:	e9 f6 fe ff ff       	jmp    f010082b <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100935:	83 c4 5c             	add    $0x5c,%esp
f0100938:	5b                   	pop    %ebx
f0100939:	5e                   	pop    %esi
f010093a:	5f                   	pop    %edi
f010093b:	5d                   	pop    %ebp
f010093c:	c3                   	ret    
f010093d:	66 90                	xchg   %ax,%ax
f010093f:	90                   	nop

f0100940 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100940:	55                   	push   %ebp
f0100941:	89 e5                	mov    %esp,%ebp
f0100943:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100946:	8b 45 08             	mov    0x8(%ebp),%eax
f0100949:	89 04 24             	mov    %eax,(%esp)
f010094c:	e8 00 fd ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f0100951:	c9                   	leave  
f0100952:	c3                   	ret    

f0100953 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100953:	55                   	push   %ebp
f0100954:	89 e5                	mov    %esp,%ebp
f0100956:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100959:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100960:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100963:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100967:	8b 45 08             	mov    0x8(%ebp),%eax
f010096a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010096e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100971:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100975:	c7 04 24 40 09 10 f0 	movl   $0xf0100940,(%esp)
f010097c:	e8 13 04 00 00       	call   f0100d94 <vprintfmt>
	return cnt;
}
f0100981:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100984:	c9                   	leave  
f0100985:	c3                   	ret    

f0100986 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100986:	55                   	push   %ebp
f0100987:	89 e5                	mov    %esp,%ebp
f0100989:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010098c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010098f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100993:	8b 45 08             	mov    0x8(%ebp),%eax
f0100996:	89 04 24             	mov    %eax,(%esp)
f0100999:	e8 b5 ff ff ff       	call   f0100953 <vcprintf>
	va_end(ap);

	return cnt;
}
f010099e:	c9                   	leave  
f010099f:	c3                   	ret    

f01009a0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009a0:	55                   	push   %ebp
f01009a1:	89 e5                	mov    %esp,%ebp
f01009a3:	57                   	push   %edi
f01009a4:	56                   	push   %esi
f01009a5:	53                   	push   %ebx
f01009a6:	83 ec 10             	sub    $0x10,%esp
f01009a9:	89 c6                	mov    %eax,%esi
f01009ab:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009ae:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009b1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009b4:	8b 1a                	mov    (%edx),%ebx
f01009b6:	8b 01                	mov    (%ecx),%eax
f01009b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009bb:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01009c2:	eb 77                	jmp    f0100a3b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01009c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009c7:	01 d8                	add    %ebx,%eax
f01009c9:	b9 02 00 00 00       	mov    $0x2,%ecx
f01009ce:	99                   	cltd   
f01009cf:	f7 f9                	idiv   %ecx
f01009d1:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009d3:	eb 01                	jmp    f01009d6 <stab_binsearch+0x36>
			m--;
f01009d5:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009d6:	39 d9                	cmp    %ebx,%ecx
f01009d8:	7c 1d                	jl     f01009f7 <stab_binsearch+0x57>
f01009da:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009dd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009e2:	39 fa                	cmp    %edi,%edx
f01009e4:	75 ef                	jne    f01009d5 <stab_binsearch+0x35>
f01009e6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009e9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009ec:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01009f0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009f3:	73 18                	jae    f0100a0d <stab_binsearch+0x6d>
f01009f5:	eb 05                	jmp    f01009fc <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009f7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009fa:	eb 3f                	jmp    f0100a3b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009fc:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009ff:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a01:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a04:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a0b:	eb 2e                	jmp    f0100a3b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a0d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a10:	73 15                	jae    f0100a27 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a12:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a15:	48                   	dec    %eax
f0100a16:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a19:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a1c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a1e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a25:	eb 14                	jmp    f0100a3b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a27:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a2a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a2d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a2f:	ff 45 0c             	incl   0xc(%ebp)
f0100a32:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a34:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a3b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a3e:	7e 84                	jle    f01009c4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a40:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a44:	75 0d                	jne    f0100a53 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a46:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a49:	8b 00                	mov    (%eax),%eax
f0100a4b:	48                   	dec    %eax
f0100a4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a4f:	89 07                	mov    %eax,(%edi)
f0100a51:	eb 22                	jmp    f0100a75 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a53:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a56:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a58:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a5b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5d:	eb 01                	jmp    f0100a60 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a5f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a60:	39 c1                	cmp    %eax,%ecx
f0100a62:	7d 0c                	jge    f0100a70 <stab_binsearch+0xd0>
f0100a64:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a67:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a6c:	39 fa                	cmp    %edi,%edx
f0100a6e:	75 ef                	jne    f0100a5f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a70:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a73:	89 07                	mov    %eax,(%edi)
	}
}
f0100a75:	83 c4 10             	add    $0x10,%esp
f0100a78:	5b                   	pop    %ebx
f0100a79:	5e                   	pop    %esi
f0100a7a:	5f                   	pop    %edi
f0100a7b:	5d                   	pop    %ebp
f0100a7c:	c3                   	ret    

f0100a7d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a7d:	55                   	push   %ebp
f0100a7e:	89 e5                	mov    %esp,%ebp
f0100a80:	57                   	push   %edi
f0100a81:	56                   	push   %esi
f0100a82:	53                   	push   %ebx
f0100a83:	83 ec 2c             	sub    $0x2c,%esp
f0100a86:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a89:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a8c:	c7 03 c4 1e 10 f0    	movl   $0xf0101ec4,(%ebx)
	info->eip_line = 0;
f0100a92:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a99:	c7 43 08 c4 1e 10 f0 	movl   $0xf0101ec4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aa0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aa7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aaa:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ab1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ab7:	76 12                	jbe    f0100acb <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ab9:	b8 f2 72 10 f0       	mov    $0xf01072f2,%eax
f0100abe:	3d 1d 5a 10 f0       	cmp    $0xf0105a1d,%eax
f0100ac3:	0f 86 6b 01 00 00    	jbe    f0100c34 <debuginfo_eip+0x1b7>
f0100ac9:	eb 1c                	jmp    f0100ae7 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100acb:	c7 44 24 08 ce 1e 10 	movl   $0xf0101ece,0x8(%esp)
f0100ad2:	f0 
f0100ad3:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ada:	00 
f0100adb:	c7 04 24 db 1e 10 f0 	movl   $0xf0101edb,(%esp)
f0100ae2:	e8 11 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ae7:	80 3d f1 72 10 f0 00 	cmpb   $0x0,0xf01072f1
f0100aee:	0f 85 47 01 00 00    	jne    f0100c3b <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100af4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100afb:	b8 1c 5a 10 f0       	mov    $0xf0105a1c,%eax
f0100b00:	2d 10 21 10 f0       	sub    $0xf0102110,%eax
f0100b05:	c1 f8 02             	sar    $0x2,%eax
f0100b08:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b0e:	83 e8 01             	sub    $0x1,%eax
f0100b11:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b14:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b18:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b1f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b22:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b25:	b8 10 21 10 f0       	mov    $0xf0102110,%eax
f0100b2a:	e8 71 fe ff ff       	call   f01009a0 <stab_binsearch>
	if (lfile == 0)
f0100b2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b32:	85 c0                	test   %eax,%eax
f0100b34:	0f 84 08 01 00 00    	je     f0100c42 <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b3a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b40:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b43:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b47:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b4e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b51:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b54:	b8 10 21 10 f0       	mov    $0xf0102110,%eax
f0100b59:	e8 42 fe ff ff       	call   f01009a0 <stab_binsearch>

	if (lfun <= rfun) {
f0100b5e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b61:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b64:	7f 2e                	jg     f0100b94 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b66:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b69:	8d 90 10 21 10 f0    	lea    -0xfefdef0(%eax),%edx
f0100b6f:	8b 80 10 21 10 f0    	mov    -0xfefdef0(%eax),%eax
f0100b75:	b9 f2 72 10 f0       	mov    $0xf01072f2,%ecx
f0100b7a:	81 e9 1d 5a 10 f0    	sub    $0xf0105a1d,%ecx
f0100b80:	39 c8                	cmp    %ecx,%eax
f0100b82:	73 08                	jae    f0100b8c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b84:	05 1d 5a 10 f0       	add    $0xf0105a1d,%eax
f0100b89:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b8c:	8b 42 08             	mov    0x8(%edx),%eax
f0100b8f:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b92:	eb 06                	jmp    f0100b9a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b94:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b9a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100ba1:	00 
f0100ba2:	8b 43 08             	mov    0x8(%ebx),%eax
f0100ba5:	89 04 24             	mov    %eax,(%esp)
f0100ba8:	e8 0e 09 00 00       	call   f01014bb <strfind>
f0100bad:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bb0:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bb3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100bb6:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bb9:	05 10 21 10 f0       	add    $0xf0102110,%eax
f0100bbe:	eb 06                	jmp    f0100bc6 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bc0:	83 ef 01             	sub    $0x1,%edi
f0100bc3:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bc6:	39 cf                	cmp    %ecx,%edi
f0100bc8:	7c 33                	jl     f0100bfd <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100bca:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100bce:	80 fa 84             	cmp    $0x84,%dl
f0100bd1:	74 0b                	je     f0100bde <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bd3:	80 fa 64             	cmp    $0x64,%dl
f0100bd6:	75 e8                	jne    f0100bc0 <debuginfo_eip+0x143>
f0100bd8:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bdc:	74 e2                	je     f0100bc0 <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bde:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100be1:	8b 87 10 21 10 f0    	mov    -0xfefdef0(%edi),%eax
f0100be7:	ba f2 72 10 f0       	mov    $0xf01072f2,%edx
f0100bec:	81 ea 1d 5a 10 f0    	sub    $0xf0105a1d,%edx
f0100bf2:	39 d0                	cmp    %edx,%eax
f0100bf4:	73 07                	jae    f0100bfd <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bf6:	05 1d 5a 10 f0       	add    $0xf0105a1d,%eax
f0100bfb:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bfd:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c00:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c03:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c08:	39 f1                	cmp    %esi,%ecx
f0100c0a:	7d 42                	jge    f0100c4e <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100c0c:	8d 51 01             	lea    0x1(%ecx),%edx
f0100c0f:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100c12:	05 10 21 10 f0       	add    $0xf0102110,%eax
f0100c17:	eb 07                	jmp    f0100c20 <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c19:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c1d:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c20:	39 f2                	cmp    %esi,%edx
f0100c22:	74 25                	je     f0100c49 <debuginfo_eip+0x1cc>
f0100c24:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c27:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c2b:	74 ec                	je     f0100c19 <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c32:	eb 1a                	jmp    f0100c4e <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c39:	eb 13                	jmp    f0100c4e <debuginfo_eip+0x1d1>
f0100c3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c40:	eb 0c                	jmp    f0100c4e <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c47:	eb 05                	jmp    f0100c4e <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c49:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c4e:	83 c4 2c             	add    $0x2c,%esp
f0100c51:	5b                   	pop    %ebx
f0100c52:	5e                   	pop    %esi
f0100c53:	5f                   	pop    %edi
f0100c54:	5d                   	pop    %ebp
f0100c55:	c3                   	ret    
f0100c56:	66 90                	xchg   %ax,%ax
f0100c58:	66 90                	xchg   %ax,%ax
f0100c5a:	66 90                	xchg   %ax,%ax
f0100c5c:	66 90                	xchg   %ax,%ax
f0100c5e:	66 90                	xchg   %ax,%ax

f0100c60 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c60:	55                   	push   %ebp
f0100c61:	89 e5                	mov    %esp,%ebp
f0100c63:	57                   	push   %edi
f0100c64:	56                   	push   %esi
f0100c65:	53                   	push   %ebx
f0100c66:	83 ec 3c             	sub    $0x3c,%esp
f0100c69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c6c:	89 d7                	mov    %edx,%edi
f0100c6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c77:	89 c3                	mov    %eax,%ebx
f0100c79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c7c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c7f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c82:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c87:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c8a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c8d:	39 d9                	cmp    %ebx,%ecx
f0100c8f:	72 05                	jb     f0100c96 <printnum+0x36>
f0100c91:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c94:	77 69                	ja     f0100cff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c96:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c99:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c9d:	83 ee 01             	sub    $0x1,%esi
f0100ca0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100ca4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ca8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100cac:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100cb0:	89 c3                	mov    %eax,%ebx
f0100cb2:	89 d6                	mov    %edx,%esi
f0100cb4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100cb7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100cba:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100cbe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc5:	89 04 24             	mov    %eax,(%esp)
f0100cc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ccb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ccf:	e8 0c 0a 00 00       	call   f01016e0 <__udivdi3>
f0100cd4:	89 d9                	mov    %ebx,%ecx
f0100cd6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cda:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cde:	89 04 24             	mov    %eax,(%esp)
f0100ce1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ce5:	89 fa                	mov    %edi,%edx
f0100ce7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cea:	e8 71 ff ff ff       	call   f0100c60 <printnum>
f0100cef:	eb 1b                	jmp    f0100d0c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cf1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cf5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100cf8:	89 04 24             	mov    %eax,(%esp)
f0100cfb:	ff d3                	call   *%ebx
f0100cfd:	eb 03                	jmp    f0100d02 <printnum+0xa2>
f0100cff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d02:	83 ee 01             	sub    $0x1,%esi
f0100d05:	85 f6                	test   %esi,%esi
f0100d07:	7f e8                	jg     f0100cf1 <printnum+0x91>
f0100d09:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d10:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d14:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d1a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d1e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d25:	89 04 24             	mov    %eax,(%esp)
f0100d28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d2f:	e8 dc 0a 00 00       	call   f0101810 <__umoddi3>
f0100d34:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d38:	0f be 80 e9 1e 10 f0 	movsbl -0xfefe117(%eax),%eax
f0100d3f:	89 04 24             	mov    %eax,(%esp)
f0100d42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d45:	ff d0                	call   *%eax
}
f0100d47:	83 c4 3c             	add    $0x3c,%esp
f0100d4a:	5b                   	pop    %ebx
f0100d4b:	5e                   	pop    %esi
f0100d4c:	5f                   	pop    %edi
f0100d4d:	5d                   	pop    %ebp
f0100d4e:	c3                   	ret    

f0100d4f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d4f:	55                   	push   %ebp
f0100d50:	89 e5                	mov    %esp,%ebp
f0100d52:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d55:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d59:	8b 10                	mov    (%eax),%edx
f0100d5b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d5e:	73 0a                	jae    f0100d6a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d60:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d63:	89 08                	mov    %ecx,(%eax)
f0100d65:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d68:	88 02                	mov    %al,(%edx)
}
f0100d6a:	5d                   	pop    %ebp
f0100d6b:	c3                   	ret    

f0100d6c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d6c:	55                   	push   %ebp
f0100d6d:	89 e5                	mov    %esp,%ebp
f0100d6f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d72:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d75:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d79:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d7c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d87:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d8a:	89 04 24             	mov    %eax,(%esp)
f0100d8d:	e8 02 00 00 00       	call   f0100d94 <vprintfmt>
	va_end(ap);
}
f0100d92:	c9                   	leave  
f0100d93:	c3                   	ret    

f0100d94 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d94:	55                   	push   %ebp
f0100d95:	89 e5                	mov    %esp,%ebp
f0100d97:	57                   	push   %edi
f0100d98:	56                   	push   %esi
f0100d99:	53                   	push   %ebx
f0100d9a:	83 ec 3c             	sub    $0x3c,%esp
f0100d9d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100da0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100da3:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100da6:	eb 11                	jmp    f0100db9 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100da8:	85 c0                	test   %eax,%eax
f0100daa:	0f 84 48 04 00 00    	je     f01011f8 <vprintfmt+0x464>
				return;
			putch(ch, putdat);
f0100db0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100db4:	89 04 24             	mov    %eax,(%esp)
f0100db7:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100db9:	83 c7 01             	add    $0x1,%edi
f0100dbc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100dc0:	83 f8 25             	cmp    $0x25,%eax
f0100dc3:	75 e3                	jne    f0100da8 <vprintfmt+0x14>
f0100dc5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100dc9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dd0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100dd7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100dde:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100de3:	eb 1f                	jmp    f0100e04 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100de8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100dec:	eb 16                	jmp    f0100e04 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100df1:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100df5:	eb 0d                	jmp    f0100e04 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100df7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100dfa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dfd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e04:	8d 47 01             	lea    0x1(%edi),%eax
f0100e07:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e0a:	0f b6 17             	movzbl (%edi),%edx
f0100e0d:	0f b6 c2             	movzbl %dl,%eax
f0100e10:	83 ea 23             	sub    $0x23,%edx
f0100e13:	80 fa 55             	cmp    $0x55,%dl
f0100e16:	0f 87 bf 03 00 00    	ja     f01011db <vprintfmt+0x447>
f0100e1c:	0f b6 d2             	movzbl %dl,%edx
f0100e1f:	ff 24 95 80 1f 10 f0 	jmp    *-0xfefe080(,%edx,4)
f0100e26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e29:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e2e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e31:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e34:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e38:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100e3b:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e3e:	83 f9 09             	cmp    $0x9,%ecx
f0100e41:	77 3c                	ja     f0100e7f <vprintfmt+0xeb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e43:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e46:	eb e9                	jmp    f0100e31 <vprintfmt+0x9d>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e48:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e4b:	8b 00                	mov    (%eax),%eax
f0100e4d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e50:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e53:	8d 40 04             	lea    0x4(%eax),%eax
f0100e56:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e59:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e5c:	eb 27                	jmp    f0100e85 <vprintfmt+0xf1>
f0100e5e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e61:	85 d2                	test   %edx,%edx
f0100e63:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e68:	0f 49 c2             	cmovns %edx,%eax
f0100e6b:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e71:	eb 91                	jmp    f0100e04 <vprintfmt+0x70>
f0100e73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e76:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e7d:	eb 85                	jmp    f0100e04 <vprintfmt+0x70>
f0100e7f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e82:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e85:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e89:	0f 89 75 ff ff ff    	jns    f0100e04 <vprintfmt+0x70>
f0100e8f:	e9 63 ff ff ff       	jmp    f0100df7 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e94:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e9a:	e9 65 ff ff ff       	jmp    f0100e04 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9f:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ea2:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100ea6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eaa:	8b 00                	mov    (%eax),%eax
f0100eac:	89 04 24             	mov    %eax,(%esp)
f0100eaf:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100eb4:	e9 00 ff ff ff       	jmp    f0100db9 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb9:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ebc:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100ec0:	8b 00                	mov    (%eax),%eax
f0100ec2:	99                   	cltd   
f0100ec3:	31 d0                	xor    %edx,%eax
f0100ec5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ec7:	83 f8 07             	cmp    $0x7,%eax
f0100eca:	7f 0b                	jg     f0100ed7 <vprintfmt+0x143>
f0100ecc:	8b 14 85 e0 20 10 f0 	mov    -0xfefdf20(,%eax,4),%edx
f0100ed3:	85 d2                	test   %edx,%edx
f0100ed5:	75 20                	jne    f0100ef7 <vprintfmt+0x163>
				printfmt(putch, putdat, "error %d", err);
f0100ed7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100edb:	c7 44 24 08 01 1f 10 	movl   $0xf0101f01,0x8(%esp)
f0100ee2:	f0 
f0100ee3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ee7:	89 34 24             	mov    %esi,(%esp)
f0100eea:	e8 7d fe ff ff       	call   f0100d6c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ef2:	e9 c2 fe ff ff       	jmp    f0100db9 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100ef7:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100efb:	c7 44 24 08 0a 1f 10 	movl   $0xf0101f0a,0x8(%esp)
f0100f02:	f0 
f0100f03:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f07:	89 34 24             	mov    %esi,(%esp)
f0100f0a:	e8 5d fe ff ff       	call   f0100d6c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f12:	e9 a2 fe ff ff       	jmp    f0100db9 <vprintfmt+0x25>
f0100f17:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f1d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f20:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f23:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f27:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f29:	85 ff                	test   %edi,%edi
f0100f2b:	b8 fa 1e 10 f0       	mov    $0xf0101efa,%eax
f0100f30:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f33:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f37:	0f 84 92 00 00 00    	je     f0100fcf <vprintfmt+0x23b>
f0100f3d:	85 c9                	test   %ecx,%ecx
f0100f3f:	0f 8e 98 00 00 00    	jle    f0100fdd <vprintfmt+0x249>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f45:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f49:	89 3c 24             	mov    %edi,(%esp)
f0100f4c:	e8 17 04 00 00       	call   f0101368 <strnlen>
f0100f51:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f54:	29 c1                	sub    %eax,%ecx
f0100f56:	89 4d cc             	mov    %ecx,-0x34(%ebp)
					putch(padc, putdat);
f0100f59:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f5d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f60:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f63:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f65:	eb 0f                	jmp    f0100f76 <vprintfmt+0x1e2>
					putch(padc, putdat);
f0100f67:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f6e:	89 04 24             	mov    %eax,(%esp)
f0100f71:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f73:	83 ef 01             	sub    $0x1,%edi
f0100f76:	85 ff                	test   %edi,%edi
f0100f78:	7f ed                	jg     f0100f67 <vprintfmt+0x1d3>
f0100f7a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f7d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f80:	85 c9                	test   %ecx,%ecx
f0100f82:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f87:	0f 49 c1             	cmovns %ecx,%eax
f0100f8a:	29 c1                	sub    %eax,%ecx
f0100f8c:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f8f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f92:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f95:	89 cb                	mov    %ecx,%ebx
f0100f97:	eb 50                	jmp    f0100fe9 <vprintfmt+0x255>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f99:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f9d:	74 1e                	je     f0100fbd <vprintfmt+0x229>
f0100f9f:	0f be d2             	movsbl %dl,%edx
f0100fa2:	83 ea 20             	sub    $0x20,%edx
f0100fa5:	83 fa 5e             	cmp    $0x5e,%edx
f0100fa8:	76 13                	jbe    f0100fbd <vprintfmt+0x229>
					putch('?', putdat);
f0100faa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fad:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fb1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fb8:	ff 55 08             	call   *0x8(%ebp)
f0100fbb:	eb 0d                	jmp    f0100fca <vprintfmt+0x236>
				else
					putch(ch, putdat);
f0100fbd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100fc0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100fc4:	89 04 24             	mov    %eax,(%esp)
f0100fc7:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fca:	83 eb 01             	sub    $0x1,%ebx
f0100fcd:	eb 1a                	jmp    f0100fe9 <vprintfmt+0x255>
f0100fcf:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fd2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fd5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fd8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fdb:	eb 0c                	jmp    f0100fe9 <vprintfmt+0x255>
f0100fdd:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fe0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fe3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fe6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fe9:	83 c7 01             	add    $0x1,%edi
f0100fec:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0100ff0:	0f be c2             	movsbl %dl,%eax
f0100ff3:	85 c0                	test   %eax,%eax
f0100ff5:	74 25                	je     f010101c <vprintfmt+0x288>
f0100ff7:	85 f6                	test   %esi,%esi
f0100ff9:	78 9e                	js     f0100f99 <vprintfmt+0x205>
f0100ffb:	83 ee 01             	sub    $0x1,%esi
f0100ffe:	79 99                	jns    f0100f99 <vprintfmt+0x205>
f0101000:	89 df                	mov    %ebx,%edi
f0101002:	8b 75 08             	mov    0x8(%ebp),%esi
f0101005:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101008:	eb 1a                	jmp    f0101024 <vprintfmt+0x290>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010100a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010100e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101015:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101017:	83 ef 01             	sub    $0x1,%edi
f010101a:	eb 08                	jmp    f0101024 <vprintfmt+0x290>
f010101c:	89 df                	mov    %ebx,%edi
f010101e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101021:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101024:	85 ff                	test   %edi,%edi
f0101026:	7f e2                	jg     f010100a <vprintfmt+0x276>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101028:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010102b:	e9 89 fd ff ff       	jmp    f0100db9 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101030:	83 f9 01             	cmp    $0x1,%ecx
f0101033:	7e 19                	jle    f010104e <vprintfmt+0x2ba>
		return va_arg(*ap, long long);
f0101035:	8b 45 14             	mov    0x14(%ebp),%eax
f0101038:	8b 50 04             	mov    0x4(%eax),%edx
f010103b:	8b 00                	mov    (%eax),%eax
f010103d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101040:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101043:	8b 45 14             	mov    0x14(%ebp),%eax
f0101046:	8d 40 08             	lea    0x8(%eax),%eax
f0101049:	89 45 14             	mov    %eax,0x14(%ebp)
f010104c:	eb 38                	jmp    f0101086 <vprintfmt+0x2f2>
	else if (lflag)
f010104e:	85 c9                	test   %ecx,%ecx
f0101050:	74 1b                	je     f010106d <vprintfmt+0x2d9>
		return va_arg(*ap, long);
f0101052:	8b 45 14             	mov    0x14(%ebp),%eax
f0101055:	8b 00                	mov    (%eax),%eax
f0101057:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010105a:	89 c1                	mov    %eax,%ecx
f010105c:	c1 f9 1f             	sar    $0x1f,%ecx
f010105f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101062:	8b 45 14             	mov    0x14(%ebp),%eax
f0101065:	8d 40 04             	lea    0x4(%eax),%eax
f0101068:	89 45 14             	mov    %eax,0x14(%ebp)
f010106b:	eb 19                	jmp    f0101086 <vprintfmt+0x2f2>
	else
		return va_arg(*ap, int);
f010106d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101070:	8b 00                	mov    (%eax),%eax
f0101072:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101075:	89 c1                	mov    %eax,%ecx
f0101077:	c1 f9 1f             	sar    $0x1f,%ecx
f010107a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010107d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101080:	8d 40 04             	lea    0x4(%eax),%eax
f0101083:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101086:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101089:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010108c:	bf 0a 00 00 00       	mov    $0xa,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101091:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101095:	0f 89 04 01 00 00    	jns    f010119f <vprintfmt+0x40b>
				putch('-', putdat);
f010109b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010109f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010a6:	ff d6                	call   *%esi
				num = -(long long) num;
f01010a8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010ab:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010ae:	f7 da                	neg    %edx
f01010b0:	83 d1 00             	adc    $0x0,%ecx
f01010b3:	f7 d9                	neg    %ecx
f01010b5:	e9 e5 00 00 00       	jmp    f010119f <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010ba:	83 f9 01             	cmp    $0x1,%ecx
f01010bd:	7e 10                	jle    f01010cf <vprintfmt+0x33b>
		return va_arg(*ap, unsigned long long);
f01010bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c2:	8b 10                	mov    (%eax),%edx
f01010c4:	8b 48 04             	mov    0x4(%eax),%ecx
f01010c7:	8d 40 08             	lea    0x8(%eax),%eax
f01010ca:	89 45 14             	mov    %eax,0x14(%ebp)
f01010cd:	eb 26                	jmp    f01010f5 <vprintfmt+0x361>
	else if (lflag)
f01010cf:	85 c9                	test   %ecx,%ecx
f01010d1:	74 12                	je     f01010e5 <vprintfmt+0x351>
		return va_arg(*ap, unsigned long);
f01010d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d6:	8b 10                	mov    (%eax),%edx
f01010d8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010dd:	8d 40 04             	lea    0x4(%eax),%eax
f01010e0:	89 45 14             	mov    %eax,0x14(%ebp)
f01010e3:	eb 10                	jmp    f01010f5 <vprintfmt+0x361>
	else
		return va_arg(*ap, unsigned int);
f01010e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e8:	8b 10                	mov    (%eax),%edx
f01010ea:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010ef:	8d 40 04             	lea    0x4(%eax),%eax
f01010f2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010f5:	bf 0a 00 00 00       	mov    $0xa,%edi
			goto number;
f01010fa:	e9 a0 00 00 00       	jmp    f010119f <vprintfmt+0x40b>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101103:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010110a:	ff d6                	call   *%esi
			putch('X', putdat);
f010110c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101110:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101117:	ff d6                	call   *%esi
			putch('X', putdat);
f0101119:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010111d:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101124:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101126:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101129:	e9 8b fc ff ff       	jmp    f0100db9 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f010112e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101132:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101139:	ff d6                	call   *%esi
			putch('x', putdat);
f010113b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010113f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101146:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101148:	8b 45 14             	mov    0x14(%ebp),%eax
f010114b:	8b 10                	mov    (%eax),%edx
f010114d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0101152:	8d 40 04             	lea    0x4(%eax),%eax
f0101155:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101158:	bf 10 00 00 00       	mov    $0x10,%edi
			goto number;
f010115d:	eb 40                	jmp    f010119f <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010115f:	83 f9 01             	cmp    $0x1,%ecx
f0101162:	7e 10                	jle    f0101174 <vprintfmt+0x3e0>
		return va_arg(*ap, unsigned long long);
f0101164:	8b 45 14             	mov    0x14(%ebp),%eax
f0101167:	8b 10                	mov    (%eax),%edx
f0101169:	8b 48 04             	mov    0x4(%eax),%ecx
f010116c:	8d 40 08             	lea    0x8(%eax),%eax
f010116f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101172:	eb 26                	jmp    f010119a <vprintfmt+0x406>
	else if (lflag)
f0101174:	85 c9                	test   %ecx,%ecx
f0101176:	74 12                	je     f010118a <vprintfmt+0x3f6>
		return va_arg(*ap, unsigned long);
f0101178:	8b 45 14             	mov    0x14(%ebp),%eax
f010117b:	8b 10                	mov    (%eax),%edx
f010117d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101182:	8d 40 04             	lea    0x4(%eax),%eax
f0101185:	89 45 14             	mov    %eax,0x14(%ebp)
f0101188:	eb 10                	jmp    f010119a <vprintfmt+0x406>
	else
		return va_arg(*ap, unsigned int);
f010118a:	8b 45 14             	mov    0x14(%ebp),%eax
f010118d:	8b 10                	mov    (%eax),%edx
f010118f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101194:	8d 40 04             	lea    0x4(%eax),%eax
f0101197:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010119a:	bf 10 00 00 00       	mov    $0x10,%edi
		number:
			printnum(putch, putdat, num, base, width, padc);
f010119f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01011a3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01011a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011ae:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01011b2:	89 14 24             	mov    %edx,(%esp)
f01011b5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01011b9:	89 da                	mov    %ebx,%edx
f01011bb:	89 f0                	mov    %esi,%eax
f01011bd:	e8 9e fa ff ff       	call   f0100c60 <printnum>
			break;
f01011c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01011c5:	e9 ef fb ff ff       	jmp    f0100db9 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ce:	89 04 24             	mov    %eax,(%esp)
f01011d1:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011d6:	e9 de fb ff ff       	jmp    f0100db9 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011df:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011e6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011e8:	eb 03                	jmp    f01011ed <vprintfmt+0x459>
f01011ea:	83 ef 01             	sub    $0x1,%edi
f01011ed:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011f1:	75 f7                	jne    f01011ea <vprintfmt+0x456>
f01011f3:	e9 c1 fb ff ff       	jmp    f0100db9 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01011f8:	83 c4 3c             	add    $0x3c,%esp
f01011fb:	5b                   	pop    %ebx
f01011fc:	5e                   	pop    %esi
f01011fd:	5f                   	pop    %edi
f01011fe:	5d                   	pop    %ebp
f01011ff:	c3                   	ret    

f0101200 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101200:	55                   	push   %ebp
f0101201:	89 e5                	mov    %esp,%ebp
f0101203:	83 ec 28             	sub    $0x28,%esp
f0101206:	8b 45 08             	mov    0x8(%ebp),%eax
f0101209:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010120c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010120f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101213:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101216:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010121d:	85 c0                	test   %eax,%eax
f010121f:	74 30                	je     f0101251 <vsnprintf+0x51>
f0101221:	85 d2                	test   %edx,%edx
f0101223:	7e 2c                	jle    f0101251 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101225:	8b 45 14             	mov    0x14(%ebp),%eax
f0101228:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010122c:	8b 45 10             	mov    0x10(%ebp),%eax
f010122f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101233:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101236:	89 44 24 04          	mov    %eax,0x4(%esp)
f010123a:	c7 04 24 4f 0d 10 f0 	movl   $0xf0100d4f,(%esp)
f0101241:	e8 4e fb ff ff       	call   f0100d94 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101246:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101249:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010124c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010124f:	eb 05                	jmp    f0101256 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101251:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101256:	c9                   	leave  
f0101257:	c3                   	ret    

f0101258 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101258:	55                   	push   %ebp
f0101259:	89 e5                	mov    %esp,%ebp
f010125b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010125e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101261:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101265:	8b 45 10             	mov    0x10(%ebp),%eax
f0101268:	89 44 24 08          	mov    %eax,0x8(%esp)
f010126c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010126f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101273:	8b 45 08             	mov    0x8(%ebp),%eax
f0101276:	89 04 24             	mov    %eax,(%esp)
f0101279:	e8 82 ff ff ff       	call   f0101200 <vsnprintf>
	va_end(ap);

	return rc;
}
f010127e:	c9                   	leave  
f010127f:	c3                   	ret    

f0101280 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101280:	55                   	push   %ebp
f0101281:	89 e5                	mov    %esp,%ebp
f0101283:	57                   	push   %edi
f0101284:	56                   	push   %esi
f0101285:	53                   	push   %ebx
f0101286:	83 ec 1c             	sub    $0x1c,%esp
f0101289:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010128c:	85 c0                	test   %eax,%eax
f010128e:	74 10                	je     f01012a0 <readline+0x20>
		cprintf("%s", prompt);
f0101290:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101294:	c7 04 24 0a 1f 10 f0 	movl   $0xf0101f0a,(%esp)
f010129b:	e8 e6 f6 ff ff       	call   f0100986 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012a7:	e8 c6 f3 ff ff       	call   f0100672 <iscons>
f01012ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012b3:	e8 a9 f3 ff ff       	call   f0100661 <getchar>
f01012b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012ba:	85 c0                	test   %eax,%eax
f01012bc:	79 17                	jns    f01012d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c2:	c7 04 24 00 21 10 f0 	movl   $0xf0102100,(%esp)
f01012c9:	e8 b8 f6 ff ff       	call   f0100986 <cprintf>
			return NULL;
f01012ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d3:	eb 6d                	jmp    f0101342 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012d5:	83 f8 7f             	cmp    $0x7f,%eax
f01012d8:	74 05                	je     f01012df <readline+0x5f>
f01012da:	83 f8 08             	cmp    $0x8,%eax
f01012dd:	75 19                	jne    f01012f8 <readline+0x78>
f01012df:	85 f6                	test   %esi,%esi
f01012e1:	7e 15                	jle    f01012f8 <readline+0x78>
			if (echoing)
f01012e3:	85 ff                	test   %edi,%edi
f01012e5:	74 0c                	je     f01012f3 <readline+0x73>
				cputchar('\b');
f01012e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012ee:	e8 5e f3 ff ff       	call   f0100651 <cputchar>
			i--;
f01012f3:	83 ee 01             	sub    $0x1,%esi
f01012f6:	eb bb                	jmp    f01012b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012fe:	7f 1c                	jg     f010131c <readline+0x9c>
f0101300:	83 fb 1f             	cmp    $0x1f,%ebx
f0101303:	7e 17                	jle    f010131c <readline+0x9c>
			if (echoing)
f0101305:	85 ff                	test   %edi,%edi
f0101307:	74 08                	je     f0101311 <readline+0x91>
				cputchar(c);
f0101309:	89 1c 24             	mov    %ebx,(%esp)
f010130c:	e8 40 f3 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101311:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101317:	8d 76 01             	lea    0x1(%esi),%esi
f010131a:	eb 97                	jmp    f01012b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010131c:	83 fb 0d             	cmp    $0xd,%ebx
f010131f:	74 05                	je     f0101326 <readline+0xa6>
f0101321:	83 fb 0a             	cmp    $0xa,%ebx
f0101324:	75 8d                	jne    f01012b3 <readline+0x33>
			if (echoing)
f0101326:	85 ff                	test   %edi,%edi
f0101328:	74 0c                	je     f0101336 <readline+0xb6>
				cputchar('\n');
f010132a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101331:	e8 1b f3 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f0101336:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010133d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101342:	83 c4 1c             	add    $0x1c,%esp
f0101345:	5b                   	pop    %ebx
f0101346:	5e                   	pop    %esi
f0101347:	5f                   	pop    %edi
f0101348:	5d                   	pop    %ebp
f0101349:	c3                   	ret    
f010134a:	66 90                	xchg   %ax,%ax
f010134c:	66 90                	xchg   %ax,%ax
f010134e:	66 90                	xchg   %ax,%ax

f0101350 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101356:	b8 00 00 00 00       	mov    $0x0,%eax
f010135b:	eb 03                	jmp    f0101360 <strlen+0x10>
		n++;
f010135d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101360:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101364:	75 f7                	jne    f010135d <strlen+0xd>
		n++;
	return n;
}
f0101366:	5d                   	pop    %ebp
f0101367:	c3                   	ret    

f0101368 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101368:	55                   	push   %ebp
f0101369:	89 e5                	mov    %esp,%ebp
f010136b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010136e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101371:	b8 00 00 00 00       	mov    $0x0,%eax
f0101376:	eb 03                	jmp    f010137b <strnlen+0x13>
		n++;
f0101378:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010137b:	39 d0                	cmp    %edx,%eax
f010137d:	74 06                	je     f0101385 <strnlen+0x1d>
f010137f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101383:	75 f3                	jne    f0101378 <strnlen+0x10>
		n++;
	return n;
}
f0101385:	5d                   	pop    %ebp
f0101386:	c3                   	ret    

f0101387 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101387:	55                   	push   %ebp
f0101388:	89 e5                	mov    %esp,%ebp
f010138a:	53                   	push   %ebx
f010138b:	8b 45 08             	mov    0x8(%ebp),%eax
f010138e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101391:	89 c2                	mov    %eax,%edx
f0101393:	83 c2 01             	add    $0x1,%edx
f0101396:	83 c1 01             	add    $0x1,%ecx
f0101399:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010139d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013a0:	84 db                	test   %bl,%bl
f01013a2:	75 ef                	jne    f0101393 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013a4:	5b                   	pop    %ebx
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    

f01013a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	53                   	push   %ebx
f01013ab:	83 ec 08             	sub    $0x8,%esp
f01013ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01013b1:	89 1c 24             	mov    %ebx,(%esp)
f01013b4:	e8 97 ff ff ff       	call   f0101350 <strlen>
	strcpy(dst + len, src);
f01013b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013bc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01013c0:	01 d8                	add    %ebx,%eax
f01013c2:	89 04 24             	mov    %eax,(%esp)
f01013c5:	e8 bd ff ff ff       	call   f0101387 <strcpy>
	return dst;
}
f01013ca:	89 d8                	mov    %ebx,%eax
f01013cc:	83 c4 08             	add    $0x8,%esp
f01013cf:	5b                   	pop    %ebx
f01013d0:	5d                   	pop    %ebp
f01013d1:	c3                   	ret    

f01013d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013d2:	55                   	push   %ebp
f01013d3:	89 e5                	mov    %esp,%ebp
f01013d5:	56                   	push   %esi
f01013d6:	53                   	push   %ebx
f01013d7:	8b 75 08             	mov    0x8(%ebp),%esi
f01013da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013dd:	89 f3                	mov    %esi,%ebx
f01013df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013e2:	89 f2                	mov    %esi,%edx
f01013e4:	eb 0f                	jmp    f01013f5 <strncpy+0x23>
		*dst++ = *src;
f01013e6:	83 c2 01             	add    $0x1,%edx
f01013e9:	0f b6 01             	movzbl (%ecx),%eax
f01013ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013ef:	80 39 01             	cmpb   $0x1,(%ecx)
f01013f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013f5:	39 da                	cmp    %ebx,%edx
f01013f7:	75 ed                	jne    f01013e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013f9:	89 f0                	mov    %esi,%eax
f01013fb:	5b                   	pop    %ebx
f01013fc:	5e                   	pop    %esi
f01013fd:	5d                   	pop    %ebp
f01013fe:	c3                   	ret    

f01013ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013ff:	55                   	push   %ebp
f0101400:	89 e5                	mov    %esp,%ebp
f0101402:	56                   	push   %esi
f0101403:	53                   	push   %ebx
f0101404:	8b 75 08             	mov    0x8(%ebp),%esi
f0101407:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010140d:	89 f0                	mov    %esi,%eax
f010140f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101413:	85 c9                	test   %ecx,%ecx
f0101415:	75 0b                	jne    f0101422 <strlcpy+0x23>
f0101417:	eb 1d                	jmp    f0101436 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101419:	83 c0 01             	add    $0x1,%eax
f010141c:	83 c2 01             	add    $0x1,%edx
f010141f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101422:	39 d8                	cmp    %ebx,%eax
f0101424:	74 0b                	je     f0101431 <strlcpy+0x32>
f0101426:	0f b6 0a             	movzbl (%edx),%ecx
f0101429:	84 c9                	test   %cl,%cl
f010142b:	75 ec                	jne    f0101419 <strlcpy+0x1a>
f010142d:	89 c2                	mov    %eax,%edx
f010142f:	eb 02                	jmp    f0101433 <strlcpy+0x34>
f0101431:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101433:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101436:	29 f0                	sub    %esi,%eax
}
f0101438:	5b                   	pop    %ebx
f0101439:	5e                   	pop    %esi
f010143a:	5d                   	pop    %ebp
f010143b:	c3                   	ret    

f010143c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010143c:	55                   	push   %ebp
f010143d:	89 e5                	mov    %esp,%ebp
f010143f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101442:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101445:	eb 06                	jmp    f010144d <strcmp+0x11>
		p++, q++;
f0101447:	83 c1 01             	add    $0x1,%ecx
f010144a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010144d:	0f b6 01             	movzbl (%ecx),%eax
f0101450:	84 c0                	test   %al,%al
f0101452:	74 04                	je     f0101458 <strcmp+0x1c>
f0101454:	3a 02                	cmp    (%edx),%al
f0101456:	74 ef                	je     f0101447 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101458:	0f b6 c0             	movzbl %al,%eax
f010145b:	0f b6 12             	movzbl (%edx),%edx
f010145e:	29 d0                	sub    %edx,%eax
}
f0101460:	5d                   	pop    %ebp
f0101461:	c3                   	ret    

f0101462 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101462:	55                   	push   %ebp
f0101463:	89 e5                	mov    %esp,%ebp
f0101465:	53                   	push   %ebx
f0101466:	8b 45 08             	mov    0x8(%ebp),%eax
f0101469:	8b 55 0c             	mov    0xc(%ebp),%edx
f010146c:	89 c3                	mov    %eax,%ebx
f010146e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101471:	eb 06                	jmp    f0101479 <strncmp+0x17>
		n--, p++, q++;
f0101473:	83 c0 01             	add    $0x1,%eax
f0101476:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101479:	39 d8                	cmp    %ebx,%eax
f010147b:	74 15                	je     f0101492 <strncmp+0x30>
f010147d:	0f b6 08             	movzbl (%eax),%ecx
f0101480:	84 c9                	test   %cl,%cl
f0101482:	74 04                	je     f0101488 <strncmp+0x26>
f0101484:	3a 0a                	cmp    (%edx),%cl
f0101486:	74 eb                	je     f0101473 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101488:	0f b6 00             	movzbl (%eax),%eax
f010148b:	0f b6 12             	movzbl (%edx),%edx
f010148e:	29 d0                	sub    %edx,%eax
f0101490:	eb 05                	jmp    f0101497 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101492:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101497:	5b                   	pop    %ebx
f0101498:	5d                   	pop    %ebp
f0101499:	c3                   	ret    

f010149a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010149a:	55                   	push   %ebp
f010149b:	89 e5                	mov    %esp,%ebp
f010149d:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014a4:	eb 07                	jmp    f01014ad <strchr+0x13>
		if (*s == c)
f01014a6:	38 ca                	cmp    %cl,%dl
f01014a8:	74 0f                	je     f01014b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014aa:	83 c0 01             	add    $0x1,%eax
f01014ad:	0f b6 10             	movzbl (%eax),%edx
f01014b0:	84 d2                	test   %dl,%dl
f01014b2:	75 f2                	jne    f01014a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01014b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014b9:	5d                   	pop    %ebp
f01014ba:	c3                   	ret    

f01014bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
f01014be:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014c5:	eb 07                	jmp    f01014ce <strfind+0x13>
		if (*s == c)
f01014c7:	38 ca                	cmp    %cl,%dl
f01014c9:	74 0a                	je     f01014d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014cb:	83 c0 01             	add    $0x1,%eax
f01014ce:	0f b6 10             	movzbl (%eax),%edx
f01014d1:	84 d2                	test   %dl,%dl
f01014d3:	75 f2                	jne    f01014c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01014d5:	5d                   	pop    %ebp
f01014d6:	c3                   	ret    

f01014d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014d7:	55                   	push   %ebp
f01014d8:	89 e5                	mov    %esp,%ebp
f01014da:	57                   	push   %edi
f01014db:	56                   	push   %esi
f01014dc:	53                   	push   %ebx
f01014dd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014e3:	85 c9                	test   %ecx,%ecx
f01014e5:	74 36                	je     f010151d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014ed:	75 28                	jne    f0101517 <memset+0x40>
f01014ef:	f6 c1 03             	test   $0x3,%cl
f01014f2:	75 23                	jne    f0101517 <memset+0x40>
		c &= 0xFF;
f01014f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014f8:	89 d3                	mov    %edx,%ebx
f01014fa:	c1 e3 08             	shl    $0x8,%ebx
f01014fd:	89 d6                	mov    %edx,%esi
f01014ff:	c1 e6 18             	shl    $0x18,%esi
f0101502:	89 d0                	mov    %edx,%eax
f0101504:	c1 e0 10             	shl    $0x10,%eax
f0101507:	09 f0                	or     %esi,%eax
f0101509:	09 c2                	or     %eax,%edx
f010150b:	89 d0                	mov    %edx,%eax
f010150d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010150f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101512:	fc                   	cld    
f0101513:	f3 ab                	rep stos %eax,%es:(%edi)
f0101515:	eb 06                	jmp    f010151d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101517:	8b 45 0c             	mov    0xc(%ebp),%eax
f010151a:	fc                   	cld    
f010151b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010151d:	89 f8                	mov    %edi,%eax
f010151f:	5b                   	pop    %ebx
f0101520:	5e                   	pop    %esi
f0101521:	5f                   	pop    %edi
f0101522:	5d                   	pop    %ebp
f0101523:	c3                   	ret    

f0101524 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101524:	55                   	push   %ebp
f0101525:	89 e5                	mov    %esp,%ebp
f0101527:	57                   	push   %edi
f0101528:	56                   	push   %esi
f0101529:	8b 45 08             	mov    0x8(%ebp),%eax
f010152c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010152f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101532:	39 c6                	cmp    %eax,%esi
f0101534:	73 35                	jae    f010156b <memmove+0x47>
f0101536:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101539:	39 d0                	cmp    %edx,%eax
f010153b:	73 2e                	jae    f010156b <memmove+0x47>
		s += n;
		d += n;
f010153d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101540:	89 d6                	mov    %edx,%esi
f0101542:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101544:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010154a:	75 13                	jne    f010155f <memmove+0x3b>
f010154c:	f6 c1 03             	test   $0x3,%cl
f010154f:	75 0e                	jne    f010155f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101551:	83 ef 04             	sub    $0x4,%edi
f0101554:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101557:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010155a:	fd                   	std    
f010155b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010155d:	eb 09                	jmp    f0101568 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010155f:	83 ef 01             	sub    $0x1,%edi
f0101562:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101565:	fd                   	std    
f0101566:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101568:	fc                   	cld    
f0101569:	eb 1d                	jmp    f0101588 <memmove+0x64>
f010156b:	89 f2                	mov    %esi,%edx
f010156d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010156f:	f6 c2 03             	test   $0x3,%dl
f0101572:	75 0f                	jne    f0101583 <memmove+0x5f>
f0101574:	f6 c1 03             	test   $0x3,%cl
f0101577:	75 0a                	jne    f0101583 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101579:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010157c:	89 c7                	mov    %eax,%edi
f010157e:	fc                   	cld    
f010157f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101581:	eb 05                	jmp    f0101588 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101583:	89 c7                	mov    %eax,%edi
f0101585:	fc                   	cld    
f0101586:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101588:	5e                   	pop    %esi
f0101589:	5f                   	pop    %edi
f010158a:	5d                   	pop    %ebp
f010158b:	c3                   	ret    

f010158c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010158c:	55                   	push   %ebp
f010158d:	89 e5                	mov    %esp,%ebp
f010158f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101592:	8b 45 10             	mov    0x10(%ebp),%eax
f0101595:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101599:	8b 45 0c             	mov    0xc(%ebp),%eax
f010159c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a3:	89 04 24             	mov    %eax,(%esp)
f01015a6:	e8 79 ff ff ff       	call   f0101524 <memmove>
}
f01015ab:	c9                   	leave  
f01015ac:	c3                   	ret    

f01015ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015ad:	55                   	push   %ebp
f01015ae:	89 e5                	mov    %esp,%ebp
f01015b0:	56                   	push   %esi
f01015b1:	53                   	push   %ebx
f01015b2:	8b 55 08             	mov    0x8(%ebp),%edx
f01015b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015b8:	89 d6                	mov    %edx,%esi
f01015ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015bd:	eb 1a                	jmp    f01015d9 <memcmp+0x2c>
		if (*s1 != *s2)
f01015bf:	0f b6 02             	movzbl (%edx),%eax
f01015c2:	0f b6 19             	movzbl (%ecx),%ebx
f01015c5:	38 d8                	cmp    %bl,%al
f01015c7:	74 0a                	je     f01015d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01015c9:	0f b6 c0             	movzbl %al,%eax
f01015cc:	0f b6 db             	movzbl %bl,%ebx
f01015cf:	29 d8                	sub    %ebx,%eax
f01015d1:	eb 0f                	jmp    f01015e2 <memcmp+0x35>
		s1++, s2++;
f01015d3:	83 c2 01             	add    $0x1,%edx
f01015d6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015d9:	39 f2                	cmp    %esi,%edx
f01015db:	75 e2                	jne    f01015bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015e2:	5b                   	pop    %ebx
f01015e3:	5e                   	pop    %esi
f01015e4:	5d                   	pop    %ebp
f01015e5:	c3                   	ret    

f01015e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015e6:	55                   	push   %ebp
f01015e7:	89 e5                	mov    %esp,%ebp
f01015e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01015ef:	89 c2                	mov    %eax,%edx
f01015f1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015f4:	eb 07                	jmp    f01015fd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015f6:	38 08                	cmp    %cl,(%eax)
f01015f8:	74 07                	je     f0101601 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015fa:	83 c0 01             	add    $0x1,%eax
f01015fd:	39 d0                	cmp    %edx,%eax
f01015ff:	72 f5                	jb     f01015f6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101601:	5d                   	pop    %ebp
f0101602:	c3                   	ret    

f0101603 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101603:	55                   	push   %ebp
f0101604:	89 e5                	mov    %esp,%ebp
f0101606:	57                   	push   %edi
f0101607:	56                   	push   %esi
f0101608:	53                   	push   %ebx
f0101609:	8b 55 08             	mov    0x8(%ebp),%edx
f010160c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010160f:	eb 03                	jmp    f0101614 <strtol+0x11>
		s++;
f0101611:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101614:	0f b6 0a             	movzbl (%edx),%ecx
f0101617:	80 f9 09             	cmp    $0x9,%cl
f010161a:	74 f5                	je     f0101611 <strtol+0xe>
f010161c:	80 f9 20             	cmp    $0x20,%cl
f010161f:	74 f0                	je     f0101611 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101621:	80 f9 2b             	cmp    $0x2b,%cl
f0101624:	75 0a                	jne    f0101630 <strtol+0x2d>
		s++;
f0101626:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101629:	bf 00 00 00 00       	mov    $0x0,%edi
f010162e:	eb 11                	jmp    f0101641 <strtol+0x3e>
f0101630:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101635:	80 f9 2d             	cmp    $0x2d,%cl
f0101638:	75 07                	jne    f0101641 <strtol+0x3e>
		s++, neg = 1;
f010163a:	8d 52 01             	lea    0x1(%edx),%edx
f010163d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101641:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101646:	75 15                	jne    f010165d <strtol+0x5a>
f0101648:	80 3a 30             	cmpb   $0x30,(%edx)
f010164b:	75 10                	jne    f010165d <strtol+0x5a>
f010164d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101651:	75 0a                	jne    f010165d <strtol+0x5a>
		s += 2, base = 16;
f0101653:	83 c2 02             	add    $0x2,%edx
f0101656:	b8 10 00 00 00       	mov    $0x10,%eax
f010165b:	eb 10                	jmp    f010166d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010165d:	85 c0                	test   %eax,%eax
f010165f:	75 0c                	jne    f010166d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101661:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101663:	80 3a 30             	cmpb   $0x30,(%edx)
f0101666:	75 05                	jne    f010166d <strtol+0x6a>
		s++, base = 8;
f0101668:	83 c2 01             	add    $0x1,%edx
f010166b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010166d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101672:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101675:	0f b6 0a             	movzbl (%edx),%ecx
f0101678:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010167b:	89 f0                	mov    %esi,%eax
f010167d:	3c 09                	cmp    $0x9,%al
f010167f:	77 08                	ja     f0101689 <strtol+0x86>
			dig = *s - '0';
f0101681:	0f be c9             	movsbl %cl,%ecx
f0101684:	83 e9 30             	sub    $0x30,%ecx
f0101687:	eb 20                	jmp    f01016a9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101689:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010168c:	89 f0                	mov    %esi,%eax
f010168e:	3c 19                	cmp    $0x19,%al
f0101690:	77 08                	ja     f010169a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101692:	0f be c9             	movsbl %cl,%ecx
f0101695:	83 e9 57             	sub    $0x57,%ecx
f0101698:	eb 0f                	jmp    f01016a9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010169a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010169d:	89 f0                	mov    %esi,%eax
f010169f:	3c 19                	cmp    $0x19,%al
f01016a1:	77 16                	ja     f01016b9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01016a3:	0f be c9             	movsbl %cl,%ecx
f01016a6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016a9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01016ac:	7d 0f                	jge    f01016bd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01016ae:	83 c2 01             	add    $0x1,%edx
f01016b1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01016b5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01016b7:	eb bc                	jmp    f0101675 <strtol+0x72>
f01016b9:	89 d8                	mov    %ebx,%eax
f01016bb:	eb 02                	jmp    f01016bf <strtol+0xbc>
f01016bd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01016bf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016c3:	74 05                	je     f01016ca <strtol+0xc7>
		*endptr = (char *) s;
f01016c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016c8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01016ca:	f7 d8                	neg    %eax
f01016cc:	85 ff                	test   %edi,%edi
f01016ce:	0f 44 c3             	cmove  %ebx,%eax
}
f01016d1:	5b                   	pop    %ebx
f01016d2:	5e                   	pop    %esi
f01016d3:	5f                   	pop    %edi
f01016d4:	5d                   	pop    %ebp
f01016d5:	c3                   	ret    
f01016d6:	66 90                	xchg   %ax,%ax
f01016d8:	66 90                	xchg   %ax,%ax
f01016da:	66 90                	xchg   %ax,%ax
f01016dc:	66 90                	xchg   %ax,%ax
f01016de:	66 90                	xchg   %ax,%ax

f01016e0 <__udivdi3>:
f01016e0:	55                   	push   %ebp
f01016e1:	57                   	push   %edi
f01016e2:	56                   	push   %esi
f01016e3:	83 ec 0c             	sub    $0xc,%esp
f01016e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01016ea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01016ee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01016f2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01016f6:	85 c0                	test   %eax,%eax
f01016f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016fc:	89 ea                	mov    %ebp,%edx
f01016fe:	89 0c 24             	mov    %ecx,(%esp)
f0101701:	75 2d                	jne    f0101730 <__udivdi3+0x50>
f0101703:	39 e9                	cmp    %ebp,%ecx
f0101705:	77 61                	ja     f0101768 <__udivdi3+0x88>
f0101707:	85 c9                	test   %ecx,%ecx
f0101709:	89 ce                	mov    %ecx,%esi
f010170b:	75 0b                	jne    f0101718 <__udivdi3+0x38>
f010170d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101712:	31 d2                	xor    %edx,%edx
f0101714:	f7 f1                	div    %ecx
f0101716:	89 c6                	mov    %eax,%esi
f0101718:	31 d2                	xor    %edx,%edx
f010171a:	89 e8                	mov    %ebp,%eax
f010171c:	f7 f6                	div    %esi
f010171e:	89 c5                	mov    %eax,%ebp
f0101720:	89 f8                	mov    %edi,%eax
f0101722:	f7 f6                	div    %esi
f0101724:	89 ea                	mov    %ebp,%edx
f0101726:	83 c4 0c             	add    $0xc,%esp
f0101729:	5e                   	pop    %esi
f010172a:	5f                   	pop    %edi
f010172b:	5d                   	pop    %ebp
f010172c:	c3                   	ret    
f010172d:	8d 76 00             	lea    0x0(%esi),%esi
f0101730:	39 e8                	cmp    %ebp,%eax
f0101732:	77 24                	ja     f0101758 <__udivdi3+0x78>
f0101734:	0f bd e8             	bsr    %eax,%ebp
f0101737:	83 f5 1f             	xor    $0x1f,%ebp
f010173a:	75 3c                	jne    f0101778 <__udivdi3+0x98>
f010173c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101740:	39 34 24             	cmp    %esi,(%esp)
f0101743:	0f 86 9f 00 00 00    	jbe    f01017e8 <__udivdi3+0x108>
f0101749:	39 d0                	cmp    %edx,%eax
f010174b:	0f 82 97 00 00 00    	jb     f01017e8 <__udivdi3+0x108>
f0101751:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101758:	31 d2                	xor    %edx,%edx
f010175a:	31 c0                	xor    %eax,%eax
f010175c:	83 c4 0c             	add    $0xc,%esp
f010175f:	5e                   	pop    %esi
f0101760:	5f                   	pop    %edi
f0101761:	5d                   	pop    %ebp
f0101762:	c3                   	ret    
f0101763:	90                   	nop
f0101764:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101768:	89 f8                	mov    %edi,%eax
f010176a:	f7 f1                	div    %ecx
f010176c:	31 d2                	xor    %edx,%edx
f010176e:	83 c4 0c             	add    $0xc,%esp
f0101771:	5e                   	pop    %esi
f0101772:	5f                   	pop    %edi
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    
f0101775:	8d 76 00             	lea    0x0(%esi),%esi
f0101778:	89 e9                	mov    %ebp,%ecx
f010177a:	8b 3c 24             	mov    (%esp),%edi
f010177d:	d3 e0                	shl    %cl,%eax
f010177f:	89 c6                	mov    %eax,%esi
f0101781:	b8 20 00 00 00       	mov    $0x20,%eax
f0101786:	29 e8                	sub    %ebp,%eax
f0101788:	89 c1                	mov    %eax,%ecx
f010178a:	d3 ef                	shr    %cl,%edi
f010178c:	89 e9                	mov    %ebp,%ecx
f010178e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101792:	8b 3c 24             	mov    (%esp),%edi
f0101795:	09 74 24 08          	or     %esi,0x8(%esp)
f0101799:	89 d6                	mov    %edx,%esi
f010179b:	d3 e7                	shl    %cl,%edi
f010179d:	89 c1                	mov    %eax,%ecx
f010179f:	89 3c 24             	mov    %edi,(%esp)
f01017a2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017a6:	d3 ee                	shr    %cl,%esi
f01017a8:	89 e9                	mov    %ebp,%ecx
f01017aa:	d3 e2                	shl    %cl,%edx
f01017ac:	89 c1                	mov    %eax,%ecx
f01017ae:	d3 ef                	shr    %cl,%edi
f01017b0:	09 d7                	or     %edx,%edi
f01017b2:	89 f2                	mov    %esi,%edx
f01017b4:	89 f8                	mov    %edi,%eax
f01017b6:	f7 74 24 08          	divl   0x8(%esp)
f01017ba:	89 d6                	mov    %edx,%esi
f01017bc:	89 c7                	mov    %eax,%edi
f01017be:	f7 24 24             	mull   (%esp)
f01017c1:	39 d6                	cmp    %edx,%esi
f01017c3:	89 14 24             	mov    %edx,(%esp)
f01017c6:	72 30                	jb     f01017f8 <__udivdi3+0x118>
f01017c8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017cc:	89 e9                	mov    %ebp,%ecx
f01017ce:	d3 e2                	shl    %cl,%edx
f01017d0:	39 c2                	cmp    %eax,%edx
f01017d2:	73 05                	jae    f01017d9 <__udivdi3+0xf9>
f01017d4:	3b 34 24             	cmp    (%esp),%esi
f01017d7:	74 1f                	je     f01017f8 <__udivdi3+0x118>
f01017d9:	89 f8                	mov    %edi,%eax
f01017db:	31 d2                	xor    %edx,%edx
f01017dd:	e9 7a ff ff ff       	jmp    f010175c <__udivdi3+0x7c>
f01017e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017e8:	31 d2                	xor    %edx,%edx
f01017ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01017ef:	e9 68 ff ff ff       	jmp    f010175c <__udivdi3+0x7c>
f01017f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017fb:	31 d2                	xor    %edx,%edx
f01017fd:	83 c4 0c             	add    $0xc,%esp
f0101800:	5e                   	pop    %esi
f0101801:	5f                   	pop    %edi
f0101802:	5d                   	pop    %ebp
f0101803:	c3                   	ret    
f0101804:	66 90                	xchg   %ax,%ax
f0101806:	66 90                	xchg   %ax,%ax
f0101808:	66 90                	xchg   %ax,%ax
f010180a:	66 90                	xchg   %ax,%ax
f010180c:	66 90                	xchg   %ax,%ax
f010180e:	66 90                	xchg   %ax,%ax

f0101810 <__umoddi3>:
f0101810:	55                   	push   %ebp
f0101811:	57                   	push   %edi
f0101812:	56                   	push   %esi
f0101813:	83 ec 14             	sub    $0x14,%esp
f0101816:	8b 44 24 28          	mov    0x28(%esp),%eax
f010181a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010181e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101822:	89 c7                	mov    %eax,%edi
f0101824:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101828:	8b 44 24 30          	mov    0x30(%esp),%eax
f010182c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101830:	89 34 24             	mov    %esi,(%esp)
f0101833:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101837:	85 c0                	test   %eax,%eax
f0101839:	89 c2                	mov    %eax,%edx
f010183b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010183f:	75 17                	jne    f0101858 <__umoddi3+0x48>
f0101841:	39 fe                	cmp    %edi,%esi
f0101843:	76 4b                	jbe    f0101890 <__umoddi3+0x80>
f0101845:	89 c8                	mov    %ecx,%eax
f0101847:	89 fa                	mov    %edi,%edx
f0101849:	f7 f6                	div    %esi
f010184b:	89 d0                	mov    %edx,%eax
f010184d:	31 d2                	xor    %edx,%edx
f010184f:	83 c4 14             	add    $0x14,%esp
f0101852:	5e                   	pop    %esi
f0101853:	5f                   	pop    %edi
f0101854:	5d                   	pop    %ebp
f0101855:	c3                   	ret    
f0101856:	66 90                	xchg   %ax,%ax
f0101858:	39 f8                	cmp    %edi,%eax
f010185a:	77 54                	ja     f01018b0 <__umoddi3+0xa0>
f010185c:	0f bd e8             	bsr    %eax,%ebp
f010185f:	83 f5 1f             	xor    $0x1f,%ebp
f0101862:	75 5c                	jne    f01018c0 <__umoddi3+0xb0>
f0101864:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101868:	39 3c 24             	cmp    %edi,(%esp)
f010186b:	0f 87 e7 00 00 00    	ja     f0101958 <__umoddi3+0x148>
f0101871:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101875:	29 f1                	sub    %esi,%ecx
f0101877:	19 c7                	sbb    %eax,%edi
f0101879:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010187d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101881:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101885:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101889:	83 c4 14             	add    $0x14,%esp
f010188c:	5e                   	pop    %esi
f010188d:	5f                   	pop    %edi
f010188e:	5d                   	pop    %ebp
f010188f:	c3                   	ret    
f0101890:	85 f6                	test   %esi,%esi
f0101892:	89 f5                	mov    %esi,%ebp
f0101894:	75 0b                	jne    f01018a1 <__umoddi3+0x91>
f0101896:	b8 01 00 00 00       	mov    $0x1,%eax
f010189b:	31 d2                	xor    %edx,%edx
f010189d:	f7 f6                	div    %esi
f010189f:	89 c5                	mov    %eax,%ebp
f01018a1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018a5:	31 d2                	xor    %edx,%edx
f01018a7:	f7 f5                	div    %ebp
f01018a9:	89 c8                	mov    %ecx,%eax
f01018ab:	f7 f5                	div    %ebp
f01018ad:	eb 9c                	jmp    f010184b <__umoddi3+0x3b>
f01018af:	90                   	nop
f01018b0:	89 c8                	mov    %ecx,%eax
f01018b2:	89 fa                	mov    %edi,%edx
f01018b4:	83 c4 14             	add    $0x14,%esp
f01018b7:	5e                   	pop    %esi
f01018b8:	5f                   	pop    %edi
f01018b9:	5d                   	pop    %ebp
f01018ba:	c3                   	ret    
f01018bb:	90                   	nop
f01018bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018c0:	8b 04 24             	mov    (%esp),%eax
f01018c3:	be 20 00 00 00       	mov    $0x20,%esi
f01018c8:	89 e9                	mov    %ebp,%ecx
f01018ca:	29 ee                	sub    %ebp,%esi
f01018cc:	d3 e2                	shl    %cl,%edx
f01018ce:	89 f1                	mov    %esi,%ecx
f01018d0:	d3 e8                	shr    %cl,%eax
f01018d2:	89 e9                	mov    %ebp,%ecx
f01018d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018d8:	8b 04 24             	mov    (%esp),%eax
f01018db:	09 54 24 04          	or     %edx,0x4(%esp)
f01018df:	89 fa                	mov    %edi,%edx
f01018e1:	d3 e0                	shl    %cl,%eax
f01018e3:	89 f1                	mov    %esi,%ecx
f01018e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018e9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01018ed:	d3 ea                	shr    %cl,%edx
f01018ef:	89 e9                	mov    %ebp,%ecx
f01018f1:	d3 e7                	shl    %cl,%edi
f01018f3:	89 f1                	mov    %esi,%ecx
f01018f5:	d3 e8                	shr    %cl,%eax
f01018f7:	89 e9                	mov    %ebp,%ecx
f01018f9:	09 f8                	or     %edi,%eax
f01018fb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01018ff:	f7 74 24 04          	divl   0x4(%esp)
f0101903:	d3 e7                	shl    %cl,%edi
f0101905:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101909:	89 d7                	mov    %edx,%edi
f010190b:	f7 64 24 08          	mull   0x8(%esp)
f010190f:	39 d7                	cmp    %edx,%edi
f0101911:	89 c1                	mov    %eax,%ecx
f0101913:	89 14 24             	mov    %edx,(%esp)
f0101916:	72 2c                	jb     f0101944 <__umoddi3+0x134>
f0101918:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010191c:	72 22                	jb     f0101940 <__umoddi3+0x130>
f010191e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101922:	29 c8                	sub    %ecx,%eax
f0101924:	19 d7                	sbb    %edx,%edi
f0101926:	89 e9                	mov    %ebp,%ecx
f0101928:	89 fa                	mov    %edi,%edx
f010192a:	d3 e8                	shr    %cl,%eax
f010192c:	89 f1                	mov    %esi,%ecx
f010192e:	d3 e2                	shl    %cl,%edx
f0101930:	89 e9                	mov    %ebp,%ecx
f0101932:	d3 ef                	shr    %cl,%edi
f0101934:	09 d0                	or     %edx,%eax
f0101936:	89 fa                	mov    %edi,%edx
f0101938:	83 c4 14             	add    $0x14,%esp
f010193b:	5e                   	pop    %esi
f010193c:	5f                   	pop    %edi
f010193d:	5d                   	pop    %ebp
f010193e:	c3                   	ret    
f010193f:	90                   	nop
f0101940:	39 d7                	cmp    %edx,%edi
f0101942:	75 da                	jne    f010191e <__umoddi3+0x10e>
f0101944:	8b 14 24             	mov    (%esp),%edx
f0101947:	89 c1                	mov    %eax,%ecx
f0101949:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010194d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101951:	eb cb                	jmp    f010191e <__umoddi3+0x10e>
f0101953:	90                   	nop
f0101954:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101958:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010195c:	0f 82 0f ff ff ff    	jb     f0101871 <__umoddi3+0x61>
f0101962:	e9 1a ff ff ff       	jmp    f0101881 <__umoddi3+0x71>
