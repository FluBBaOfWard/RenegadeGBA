#ifdef __arm__

#include "Shared/gba_asm.h"
#include "Shared/EmuSettings.h"
#include "ARM6502/M6502.i"
#include "RenegadeVideo/RenegadeVideo.i"

	.global romNum
	.global emuFlags
	.global cartFlags
	.global romStart
	.global EMU_RAM
	.global ROM_Space
	.global testState
	.global vromBase0
	.global vromBase1
	.global vromBase2
	.global adpcmBase

	.global machineInit
	.global loadCart
	.global m6502Mapper
	.global m6502Mapper0


	.syntax unified
	.arm

	.section .rodata
	.align 8

rawRom:
ROM_Space:
/*
// Renegade
// Main cpu
	.incbin "renegade/na-5.ic52"
	.incbin "renegade/nb-5.ic51"
// Sound cpu
	.incbin "renegade/n0-5.ic13"
// MCU
//	.incbin "renegade/nz-5.ic97"
// Chars
	.incbin "renegade/nc-5.bin"
// Tiles
	.incbin "renegade/n1-5.ic1"
	.incbin "renegade/n2-5.ic14"
	.incbin "renegade/n6-5.ic28"
	.incbin "renegade/n7-5.ic27"
	.incbin "renegade/n8-5.ic26"
	.incbin "renegade/n9-5.ic25"
// Sprites
	.incbin "renegade/nh-5.bin"
	.incbin "renegade/nn-5.bin"
	.incbin "renegade/ni-5.bin"
	.incbin "renegade/no-5.bin"
	.incbin "renegade/nd-5.bin"
	.incbin "renegade/nj-5.bin"
	.incbin "renegade/ne-5.bin"
	.incbin "renegade/nk-5.bin"
	.incbin "renegade/nf-5.bin"
	.incbin "renegade/nl-5.bin"
	.incbin "renegade/ng-5.bin"
	.incbin "renegade/nm-5.bin"
// ADPCM
	.incbin "renegade/n5-5.ic31"
	.incbin "renegade/n4-5.ic32"
	.incbin "renegade/n3-5.ic33"
*/

// kuniokun
// Main cpu
	.incbin "renegade/ta18-11.bin"
	.incbin "renegade/nb-01.bin"
// Sound cpu
	.incbin "renegade/n0-5.bin"
// MCU
//	.incbin "renegade/nz-5.ic97"	;@ no dump
// Chars
	.incbin "renegade/ta18-25.bin"
// Tiles
	.incbin "renegade/ta18-01.bin"
	.incbin "renegade/ta18-02.bin"
	.incbin "renegade/ta18-06.bin"
	.incbin "renegade/n7-5.bin"
	.incbin "renegade/ta18-04.bin"
	.incbin "renegade/ta18-03.bin"
// Sprites
	.incbin "renegade/ta18-20.bin"
	.incbin "renegade/ta18-14.bin"
	.incbin "renegade/ta18-19.bin"
	.incbin "renegade/ta18-13.bin"
	.incbin "renegade/ta18-24.bin"
	.incbin "renegade/ta18-18.bin"
 	.incbin "renegade/ta18-23.bin"
	.incbin "renegade/ta18-17.bin"
	.incbin "renegade/ta18-22.bin"
	.incbin "renegade/ta18-16.bin"
	.incbin "renegade/ta18-21.bin"
	.incbin "renegade/ta18-15.bin"
// ADPCM
	.incbin "renegade/ta18-07.bin"
	.incbin "renegade/ta18-08.bin"
	.incbin "renegade/ta18-09.bin"

/*
// kuniokunb
// Main cpu
	.incbin "renegade/ta18-11.bin"
	.incbin "renegade/ta18-10.bin"
// Sound cpu
	.incbin "renegade/n0-5.bin"
// MCU
//	.incbin "renegade/nz-5.ic97"	;@ no dump
// Chars
	.incbin "renegade/ta18-25.bin"
// Tiles
	.incbin "renegade/ta18-01.bin"
	.incbin "renegade/ta18-02.bin"
	.incbin "renegade/ta18-06.bin"
	.incbin "renegade/n7-5.bin"
	.incbin "renegade/ta18-04.bin"
	.incbin "renegade/ta18-03.bin"
// Sprites
	.incbin "renegade/ta18-20.bin"
	.incbin "renegade/ta18-14.bin"
	.incbin "renegade/ta18-19.bin"
	.incbin "renegade/ta18-13.bin"
	.incbin "renegade/ta18-24.bin"
	.incbin "renegade/ta18-18.bin"
 	.incbin "renegade/ta18-23.bin"
	.incbin "renegade/ta18-17.bin"
	.incbin "renegade/ta18-22.bin"
	.incbin "renegade/ta18-16.bin"
	.incbin "renegade/ta18-21.bin"
	.incbin "renegade/ta18-15.bin"
// ADPCM
	.incbin "renegade/ta18-07.bin"
	.incbin "renegade/ta18-08.bin"
	.incbin "renegade/ta18-09.bin"
*/
	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#0x0014				;@ 3/1 wait state
	ldr r1,=REG_WAITCNT
	strh r0,[r1]

	bl gfxInit
//	bl ioInit
	bl soundInit
	bl cpuInit

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=rom number, r1=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	mov r0,#1
//	str r0,romNum
	str r1,emuFlags
	mov r11,r0

	ldr r3,=rawRom
//	ldr r3,=ROM_Space

								;@ r3=rombase til end of loadcart so DON'T FUCK IT UP
	str r3,romStart				;@ Set rom base
	add r0,r3,#0x10000			;@ 0x10000
	str r0,cpu2Base				;@ Sound cpu rom
	add r0,r0,#0x8000			;@ 0x8000
//	add r0,r0,#0x0800			;@ mcu rom 0x0800
	str r0,vromBase0			;@ Chars
	add r0,r0,#0x8000
	str r0,vromBase1			;@ Tiles
	add r0,r0,#0x30000
	str r0,vromBase2			;@ Sprites
	add r0,r0,#0x60000
	str r0,adpcmBase			;@ ADPCM data 0x18000 (0x20000)

	ldr r4,=MEMMAPTBL_
	ldr r5,=RDMEMTBL_
	ldr r6,=WRMEMTBL_
	ldr r7,=mem6502R0
	ldr r8,=rom_W
	mov r0,#0
tbLoop1:
	add r1,r3,r0,lsl#13
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]
	str r8,[r6,r0,lsl#2]
	add r0,r0,#1
	cmp r0,#0x08
	bne tbLoop1

	ldr r7,=empty_R
	ldr r8,=empty_W
tbLoop3:
	str r3,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]
	str r8,[r6,r0,lsl#2]
	add r0,r0,#1
	cmp r0,#0x100
	bne tbLoop3

	ldr r1,=EMU_RAM
	ldr r7,=mem6502R0
	ldr r8,=ram6502W
	mov r0,#0xF8				;@ RAM
	str r1,[r4,r0,lsl#2]		;@ MemMap
	str r7,[r5,r0,lsl#2]		;@ RdMem
	str r8,[r6,r0,lsl#2]		;@ WrMem

	ldr r7,=IO_R
	ldr r8,=IO_W
	mov r0,#0xFF				;@ IO
	str r1,[r4,r0,lsl#2]		;@ MemMap
	str r7,[r5,r0,lsl#2]		;@ RdMem
	str r8,[r6,r0,lsl#2]		;@ WrMem


	mov r0,#6
	mov r1,#1
	bl cacheRomPages

	mov r0,r11					;@ 0 for Renegade MCU, 1 for Kunio Kun MCU
	bl mcuReset
	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
;@ Copy rom page(s) to ram for higher speed.
;@----------------------------------------------------------------------------
cacheRomPages:				;@ r0=start page, r1=page count
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r6,lr}
	mov r4,r1					;@ Length
	ldr r5,=MEMMAPTBL_
	ldr r6,=cpuCache			;@ Destination
	add r5,r5,r0,lsl#2
moveLoop:
	ldr r1,[r5]					;@ Source
	str r6,[r5],#4				;@ Write new adr
	mov r0,r6
	add r6,r6,#0x2000
	mov r2,#0x2000
	bl memcpy
	subs r4,r4,#1
	bne moveLoop

	ldmfd sp!,{r3-r6,pc}

;@----------------------------------------------------------------------------
m6502Mapper0:
;@----------------------------------------------------------------------------
	stmfd sp!,{m6502ptr,lr}
	ldr m6502ptr,=m6502Base
	bl m6502Mapper
	ldmfd sp!,{m6502ptr,pc}
;@----------------------------------------------------------------------------
m6502Mapper:		;@ Rom paging..
;@----------------------------------------------------------------------------
	ands r0,r0,#0xFF			;@ Safety
	bxeq lr
	stmfd sp!,{r3-r8,lr}
	ldr r5,=MEMMAPTBL_
	ldr r2,[r5,r1,lsl#2]!
	ldr r3,[r5,#-1024]			;@ RDMEMTBL_
	ldr r4,[r5,#-2048]			;@ WRMEMTBL_

	mov r5,#0
	cmp r1,#0x88
	movmi r5,#12

	add r6,m6502ptr,#m6502ReadTbl
	add r7,m6502ptr,#m6502WriteTbl
	add r8,m6502ptr,#m6502MemTbl
	b m6502MemAps
m6502MemApl:
	add r6,r6,#4
	add r7,r7,#4
	add r8,r8,#4
m6502MemAp2:
	add r3,r3,r5
	sub r2,r2,#0x2000
m6502MemAps:
	movs r0,r0,lsr#1
	bcc m6502MemApl				;@ C=0
	strcs r3,[r6],#4			;@ readmem_tbl
	strcs r4,[r7],#4			;@ writemem_tb
	strcs r2,[r8],#4			;@ memmap_tbl
	bne m6502MemAp2
;@------------------------------------------
m6502MapperEnd:		;@ Update cpu_pc & lastbank
;@------------------------------------------
	ldmfd sp!,{r3-r8,lr}
	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ RomNumber
romInfo:						;@ Keep emuflags/BGmirror together for savestate/loadstate
emuFlags:
	.byte 0						;@ EmuFlags      (label this so Gui.c can take a peek) see EmuSettings.h for bitfields
	.byte SCALED				;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ Cartflags
	.space 3

romStart:
mainCpu:
	.long 0
cpu2Base:
	.long 0
vromBase0:
	.long 0
vromBase1:
	.long 0
vromBase2:
	.long 0
adpcmBase:
	.long 0
	.pool

#ifdef GBA
	.section .sbss				;@ This is EWRAM on GBA with devkitARM
#else
	.section .bss
#endif
	.align 2
WRMEMTBL_:
	.space 256*4
RDMEMTBL_:
	.space 256*4
MEMMAPTBL_:
	.space 256*4
soundCpuRam:
	.space 0x1000
NV_RAM:
EMU_RAM:
	.space 0x3200
	.space CHRBLOCKCOUNT*4
	.space BGRBLOCKCOUNT*4
	.space SPRBLOCKCOUNT*4
testState:
	.space 0x3208+0x10+0x24

	.section .bss				;@ This is IWRAM on GBA with devkitARM
cpuCache:
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
