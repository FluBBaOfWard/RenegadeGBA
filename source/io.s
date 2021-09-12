#ifdef __arm__

#include "Shared/gba_asm.h"
#include "ARM6502/M6502.i"
#include "RenegadeVideo/RenegadeVideo.i"

	.global ioReset
	.global IO_R
	.global IO_W
	.global refreshEMUjoypads

	.global joyCfg
	.global EMUinput
	.global g_dipSwitch0
	.global g_dipSwitch1
	.global g_dipSwitch2
	.global g_dipSwitch3
	.global coinCounter0
	.global coinCounter1

	.syntax unified
	.arm

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	mov r0,#0x0014				;@ 3/1 wait state
	ldr r1,=REG_WAITCNT
	strh r0,[r1]

	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------
;@	mov r11,r11
		ldr r4,=frameTotal
		ldr r4,[r4]
		movs r0,r4,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	and r0,r4,#0xf0
		ldr r2,joyCfg
		andcs r4,r4,r2
		tstcs r4,r4,lsr#10		;@ L?
		andcs r4,r4,r2,lsr#16
	adr r1,rlud2lrud
	ldrb r0,[r1,r0,lsr#4]

	ands r1,r4,#3				;@ A/B buttons to Right/Left attack
	cmpne r1,#3
	eorne r1,r1,#3
	tst r2,#0x400				;@ Swap A/B?
	andeq r1,r4,#3

	tst r1,#0x02				;@ B
	orrne r0,r0,#0x10			;@ Button 1 (atk left)
	tst r4,#0x100				;@ R
	orrne r0,r0,#0x20			;@ Button 2 (jmp)
	tst r1,#0x01				;@ A
	mov r3,#0
	orrne r3,r3,#0x04			;@ Button 4 (atk right)

	mov r1,#0
	tst r4,#0x4					;@ Select
	orrne r1,r1,#0x40			;@ Coin 1
	tst r4,#0x8					;@ Start
	orrne r1,r1,#0x4000			;@ Start 1
//	orrne r1,r1,#0x20			;@ Coin 2
	tst r2,#0x20000000			;@ Player2?
	mov r2,#0
	movne r1,r1,lsl#1
	movne r3,r3,lsl#1
	movne r2,r0
	movne r0,#0
	orr r0,r0,r1,lsr#8
	orr r2,r2,r1

	strb r0,joy0State
	strb r2,joy1State

	and r3,r3,#0x0C				;@ Attack right, P1/P2
	strb r3,joy2State
	ldrb r1,g_dipSwitch2
	bic r1,r1,#0x0C
	orr r1,r1,r3
	strb r1,g_dipSwitch2
	bx lr

joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
nrPlayers:	.long 0			;@ Number of players in multilink.
joySerial:	.byte 0
joy0State:	.byte 0
joy1State:	.byte 0
joy2State:	.byte 0
rlud2lrud:		.byte 0x00,0x01,0x02,0x03, 0x04,0x05,0x06,0x07, 0x08,0x09,0x0a,0x0b, 0x0c,0x0d,0x0e,0x0f
rlud2lrud180:	.byte 0x00,0x02,0x01,0x03, 0x08,0x0a,0x09,0x0b, 0x04,0x06,0x05,0x07, 0x0c,0x0e,0x0d,0x0f
g_dipSwitch0:	.byte 0
g_dipSwitch1:	.byte 0x50		;@ Lives, cabinet & demo sound.
g_dipSwitch2:	.byte 0
g_dipSwitch3:	.byte 0
coinCounter0:	.long 0
coinCounter1:	.long 0

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
Input0_R:		;@ Player 1 + Start
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,joy0State
	eor r0,r0,#0xFF				;@ 0x3F for test mode
	bx lr
;@----------------------------------------------------------------------------
Input1_R:		;@ Player 2 + Coin
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,joy1State
	eor r0,r0,#0xFF
	bx lr

#ifdef GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
	.align 2
#endif
;@----------------------------------------------------------------------------
Input2_R:		;@ Coin setting, Service, mcu, VBlank & attack right.
;@----------------------------------------------------------------------------
	ldr r0,=g_dipSwitch2
	ldrb r0,[r0]
//	eor r0,r0,#0x60				;@ why? MAME says ACTIVE_LOW...
	eor r0,r0,#0x9F
	bx lr
;@----------------------------------------------------------------------------
Input3_R:
;@----------------------------------------------------------------------------
	ldr r0,=g_dipSwitch1
	ldrb r0,[r0]
	eor r0,r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
IO_R:				;@ I/O read, 0x2000-0x3FFFF
;@----------------------------------------------------------------------------
	subs r1,addy,#0x3800
	bmi More_IO_R
	cmp r1,#8
	ldrmi pc,[pc,r1,lsl#2]
;@---------------------------
	b empty_IO_R
;@ io_read_tbl
	.long Input0_R			;@ 0x3800
	.long Input1_R			;@ 0x3801
	.long Input2_R			;@ 0x3802
	.long Input3_R			;@ 0x3803
	.long MCU04_R			;@ 0x3804
	.long MCU05_R			;@ 0x3805
	.long empty_IO_R		;@ 0x3806
	.long empty_IO_R		;@ 0x3807
;@----------------------------------------------------------------------------
More_IO_R:			;@ Ram,
;@----------------------------------------------------------------------------
	cmp addy,#0x3200
	ldrbmi r0,[m6502zpage,addy]
	bxmi lr
	b empty_IO_R

;@----------------------------------------------------------------------------
IO_W:				;@ I/O write, 0x2000-0x3FFFF
;@----------------------------------------------------------------------------

	cmp addy,#0x3200
	bmi ram6502W
	subs r1,addy,#0x3800
	ldrpl reptr,=reVideo_0
	bpl reIOWrite
	b empty_IO_W

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
