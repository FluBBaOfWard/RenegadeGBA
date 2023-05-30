#ifdef __arm__

#include "ARM6502/M6502.i"
#include "RenegadeVideo/RenegadeVideo.i"

	.global empty_IO_R
	.global empty_IO_W
	.global empty_R
	.global empty_W
	.global rom_W
	.global ram6502W
	.global ram6502IOW
	.global mem6502R0

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
empty_IO_R:					;@ Read bad IO address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA debugg
	mov r0,#0x10
	bx lr
;@----------------------------------------------------------------------------
empty_IO_W:					;@ Write bad IO address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA debugg
	mov r0,#0x18
	bx lr
;@----------------------------------------------------------------------------
empty_R:					;@ Read bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA debugg
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
empty_W:					;@ Write bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA debugg
	mov r0,#0xBA
	bx lr
;@----------------------------------------------------------------------------
rom_W:						;@ Write ROM address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA debugg
	mov r0,#0xB0
	bx lr
;@----------------------------------------------------------------------------

#ifdef NDS
	.section .itcm						;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2
;@----------------------------------------------------------------------------
ram6502IOW:					;@ Ram write ($2000-$31FF)
;@----------------------------------------------------------------------------
	tst addy,#0x0800
	biceq addy,addy,#0x600
;@----------------------------------------------------------------------------
ram6502W:					;@ Ram write ($0000-$31FF)
;@----------------------------------------------------------------------------
	strb r0,[m6502zpage,addy]
	ldr r1,=reVideo_0+dirtyMap
	strb m6502a,[r1,addy,lsr#11]
	bx lr

;@----------------------------------------------------------------------------
mem6502R0:					;@ Mem read ($0000-$1FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R1:					;@ Mem read ($2000-$3FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+4]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R2:					;@ Mem read ($4000-$5FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+8]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R3:					;@ Mem read ($6000-$7FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+12]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R4:					;@ Mem read ($8000-$9FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+16]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R5:					;@ Mem read ($A000-$BFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+20]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R6:					;@ Mem read ($C000-$DFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+24]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
mem6502R7:					;@ Mem read ($E000-$FFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+28]
	ldrb r0,[r1,addy]
	bx lr

;@----------------------------------------------------------------------------
;@mem6502R:					;@ Mem read ($0000-$FFFF)
;@----------------------------------------------------------------------------
;@	add r2,m6502ptr,#m6502MemTbl
;@	ldr r1,[r2,r1,lsr#11]		;@ r1=addy & 0xe000
;@	ldrb r0,[r1,addy]
;@	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
