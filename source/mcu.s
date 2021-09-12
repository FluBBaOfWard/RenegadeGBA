#ifdef __arm__

#include "ARM6502/M6502.i"

	.global mcuReset
	.global mcuSaveState
	.global mcuLoadState
	.global mcuGetStateSize
	.global MCU04_R
	.global MCU05_R
	.global MCU04_W

	.equ MCU_BUFFER_SIZE, 6

	.syntax unified
	.arm

//	.section .text
	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
mcuReset:			;@ (r0=0, Renegade. r0!=0, Kuniokun)
;@----------------------------------------------------------------------------

	cmp r0,#0
	moveq r1,#0xDA				;@ Renegade
	movne r1,#0x85				;@ Kuniokun
	strb r1,mcu_type
	moveq r1,#0x37
	movne r1,#0x2A
	strb r1,mcu_encrypt_table_len
	adreq r1,renegade_xor_table
	adrne r1,kuniokun_xor_table
	str r1,mcu_encrypt_table

	bx lr
;@----------------------------------------------------------------------------
mcuSaveState:			;@ In r0 = where to save, Out r0 = state size.
	.type   mcuSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r1,=mcuState
	mov r2,#0x10
	bl memcpy

	ldmfd sp!,{lr}
	mov r0,#0x10
	bx lr
;@----------------------------------------------------------------------------
mcuLoadState:			;@ In r0 = where to load, Out r0 = used size.
	.type   mcuLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r1,r0
	adr r0,mcuState
	mov r2,#0x10
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
mcuGetStateSize:		;@ Out r0 = state size.
	.type   mcuGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#0x10
	bx lr
;@----------------------------------------------------------------------------
MCU04_R:			;@ MCU read
;@----------------------------------------------------------------------------
	ldrb r1,mcu_input_size
	cmp r1,#0
	bne MCU_Command
mcu_ret:
	ldrb r1,mcu_output_byte
	cmp r1,#MCU_BUFFER_SIZE
	adrmi r2,mcu_buffer
	ldrbmi r0,[r2,r1]
	addmi r1,r1,#1
	strb r1,mcu_output_byte
	movpl r0,#1

	bx lr
;@----------------------------------------------------------------------------
MCU05_R:			;@ MCU read-reset
;@----------------------------------------------------------------------------
	mov r0,#-1
	str r0,mcu_key
	mov r0,#0
	strb r0,mcu_input_size
	strb r0,mcu_output_byte

	bx lr
;@----------------------------------------------------------------------------
MCU04_W:			;@ MCU write
;@----------------------------------------------------------------------------
	strb m6502a,mcu_output_byte	;@ Clear it

	ldr r1,mcu_key
	cmp r1,#0
	bpl noKeyReset

	mov r1,#0
	str r1,mcu_key
	mov r1,#1
	strb r1,mcu_input_size
	strb r0,mcu_buffer
	bx lr

noKeyReset:
	ldr r2,mcu_encrypt_table
	ldrb r2,[r2,r1]
	eor r0,r0,r2
	add r1,r1,#1
	ldrb r2,mcu_encrypt_table_len
	cmp r1,r2
	movpl r1,#0
	str r1,mcu_key
	ldrb r1,mcu_input_size
	cmp r1,#MCU_BUFFER_SIZE
	adrmi r2,mcu_buffer
	strbmi r0,[r2,r1]
	addmi r1,r1,#1
	strb r1,mcu_input_size

	bx lr
;@----------------------------------------------------------------------------
MCU_Command:		;@ Process MCU command
;@----------------------------------------------------------------------------
	strb m6502a,mcu_input_size	;@ Clear it
	strb m6502a,mcu_output_byte	;@ Clear it
	ldrb r0,mcu_buffer			;@ mcu_buffer[0]

;@	cmp r0,#0x0D				;@ Turn off MCU
;@	beq MCU_Cmd_0D
	cmp r0,#0x10
	beq MCU_Cmd_10
	cmp r0,#0x26
	beq MCU_Cmd_26
	cmp r0,#0x33
	beq MCU_Cmd_33
	cmp r0,#0x44
	beq MCU_Cmd_44
	cmp r0,#0x55
	beq MCU_Cmd_55
	cmp r0,#0x41
	beq MCU_Cmd_41
	cmp r0,#0x40
	beq MCU_Cmd_40
	cmp r0,#0x42
	beq MCU_Cmd_42

;@	debugg unknown mcu command
	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_10:			;@ Process MCU command
;@----------------------------------------------------------------------------
	ldrb r0,mcu_type
	strb r0,mcu_buffer
	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_26:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,mcu_buffer			;@ number of data bytes
	ldrb r0,mcu_buffer+1
	adr r1,sound_command_table
	ldrb r0,[r1,r0]
	strb r0,mcu_buffer+1

	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_33:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,mcu_buffer			;@ number of data bytes
	ldrb r0,mcu_buffer+2
	and r0,r0,#0x0F
	adr r1,joy_table
	ldrb r0,[r1,r0]
	strb r0,mcu_buffer+1

	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_44:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,mcu_buffer			;@ number of data bytes
	ldrb r0,mcu_buffer+2		;@ difficulty = mcu_buffer[2] & 0x3;
	and r0,r0,#0x03
	adr r1,difficulty_table		;@ result = difficulty_table[difficulty];
	ldrb r0,[r1,r0]
	ldrb r1,mcu_buffer+3		;@ stage = mcu_buffer[3];
	cmp r1,#0					;@ if (stage == 0)
	subeq r0,r0,#1				;@	result--;
	add r0,r0,r1,lsr#2			;@ result += stage / 4;
	cmp r0,#0x21				;@ if (result > 0x21)
	addhi r0,r0,#0xc0			;@	result += 0xc0;
	strb r0,mcu_buffer+1		;@ mcu_buffer[1] = result;

	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_55:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#3
	strb r0,mcu_buffer			;@ number of data bytes
	ldrb r0,mcu_buffer+4		;@ difficulty = mcu_buffer[4] & 0x3;
	and r0,r0,#3
	adr r1,timer_table
	mov r0,r0,lsl#1
	ldrh r0,[r1,r0]				;@ mcu_buffer[3] = timer_table[difficulty] & 0xff;
	strb r0,mcu_buffer+3
	mov r0,r0,lsr#8				;@ mcu_buffer[2] = timer_table[difficulty] >> 8;
	strb r0,mcu_buffer+2
	b mcu_ret

;@----------------------------------------------------------------------------
MCU_Cmd_41:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#2
	strb r0,mcu_buffer			;@ number of data bytes
	mov r0,#0x20
	strb r0,mcu_buffer+1		;@ data
	mov r0,#0x78
	strb r0,mcu_buffer+2		;@ data
	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_40:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,mcu_buffer			;@ number of data bytes
	ldrb r1,mcu_buffer+2		;@ difficulty
	mov r1,r1,lsl#1				;@ *2
	ldrb r0,mcu_buffer+3		;@ enemy type
	cmp r0,#5
	addpl r0,r1,#0x06
	addmi r0,r1,#0x18
	movpl r1,#0x20
	movmi r1,#0x40
	cmp r0,r1
	movpl r0,r1

	strb r0,mcu_buffer+1		;@ mcu_buffer[1] = health;
	b mcu_ret
;@----------------------------------------------------------------------------
MCU_Cmd_42:			;@ Process MCU command
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,mcu_buffer			;@ number of data bytes
	ldrb r0,mcu_buffer+2		;@ stage = mcu_buffer[2] & 0x3;
	and r0,r0,#3
	ldrb r1,mcu_buffer+3		;@ indx = mcu_buffer[3];
	add r1,r1,r0,lsl#3			;@ offset = stage * 8 + indx;
	cmp r0,#2					;@ if (stage >= 2)
	subpl r1,r1,#1				;@	offset--;
	adr r0,enemy_table			;@ mcu_buffer[1] = enemy_table[offset];
	ldrb r0,[r0,r1]
	strb r0,mcu_buffer+1

	b mcu_ret
;@----------------------------------------------------------------------------
joy_table:						;@ len=0x10
	.byte 0, 3, 7, 0, 1, 2, 8, 0, 5, 4, 6, 0, 0, 0, 0, 0

timer_table:					;@ len=4*2
	.short 0x4001, 0x5001, 0x1502, 0x0002

sound_command_table:			;@ len=256
	.byte 0xa0, 0xa1, 0xa2, 0x80, 0x81, 0x82, 0x83, 0x84
	.byte 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c
	.byte 0x8d, 0x8e, 0x8f, 0x97, 0x96, 0x9b, 0x9a, 0x95
	.byte 0x9e, 0x98, 0x90, 0x93, 0x9d, 0x9c, 0xa3, 0x91
	.byte 0x9f, 0x99, 0xa6, 0xae, 0x94, 0xa5, 0xa4, 0xa7
	.byte 0x92, 0xab, 0xac, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4
	.byte 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x20, 0x20
	.byte 0x50, 0x50, 0x90, 0x30, 0x30, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x80, 0xa0, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x40, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x20, 0x00, 0x00, 0x10, 0x10, 0x00, 0x00, 0x90
	.byte 0x30, 0x30, 0x30, 0xb0, 0xb0, 0xb0, 0xb0, 0xf0
	.byte 0xf0, 0xf0, 0xf0, 0xd0, 0xf0, 0x00, 0x00, 0x00
	.byte 0x00, 0x10, 0x10, 0x50, 0x30, 0xb0, 0xb0, 0xf0
	.byte 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10
	.byte 0x10, 0x10, 0x30, 0x30, 0x20, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x0f, 0x0f
	.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f
	.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x8f, 0x8f, 0x0f
	.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f
	.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0xff, 0xff, 0xff
	.byte 0xef, 0xef, 0xcf, 0x8f, 0x8f, 0x0f, 0x0f, 0x0f

enemy_table:					;@ len=0x27
	.byte 0x01, 0x06, 0x06, 0x05, 0x05, 0x05, 0x05, 0x05	;@ for stage#: 0
	.byte 0x02, 0x0a, 0x0a, 0x09, 0x09, 0x09, 0x09			;@ for stage#: 1
	.byte 0x03, 0x0e, 0x0e, 0x0e, 0x0d, 0x0d, 0x0d, 0x0d	;@ for stage#: 2
	.byte 0x04, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12	;@ for stage#: 3
	.byte 0x3d, 0x23, 0x26, 0x0a, 0xb6, 0x11, 0xa4, 0x0f	;@ strange data (maybe out of table)
	.byte 0 ;@ align

difficulty_table:				;@ len=4
	.byte 5, 3, 1, 2

renegade_xor_table:				;@ len=0x37
	.byte 0x8A, 0x48, 0x98, 0x48, 0xA9, 0x00, 0x85, 0x14
	.byte 0x85, 0x15, 0xA5, 0x11, 0x05, 0x10, 0xF0, 0x21
	.byte 0x46, 0x11, 0x66, 0x10, 0x90, 0x0F, 0x18, 0xA5
	.byte 0x14, 0x65, 0x12, 0x85, 0x14, 0xA5, 0x15, 0x65
	.byte 0x13, 0x85, 0x15, 0xB0, 0x06, 0x06, 0x12, 0x26
	.byte 0x13, 0x90, 0xDF, 0x68, 0xA8, 0x68, 0xAA, 0x38
	.byte 0x60, 0x68, 0xA8, 0x68, 0xAA, 0x18, 0x60
	.byte 0 ;@ align
kuniokun_xor_table:				;@ len=0x2a
	.byte 0x48, 0x8a, 0x48, 0xa5, 0x01, 0x48, 0xa9, 0x00
	.byte 0x85, 0x01, 0xa2, 0x10, 0x26, 0x10, 0x26, 0x11
	.byte 0x26, 0x01, 0xa5, 0x01, 0xc5, 0x00, 0x90, 0x04
	.byte 0xe5, 0x00, 0x85, 0x01, 0x26, 0x10, 0x26, 0x11
	.byte 0xca, 0xd0, 0xed, 0x68, 0x85, 0x01, 0x68, 0xaa
	.byte 0x68, 0x60
;@----------------------------------------------------------------------------
//	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
mcu_encrypt_table:
	.long 0
mcuState:
mcu_key:
	.long 0

mcu_type:
	.byte 0
mcu_encrypt_table_len:
	.byte 0
mcu_input_size:
	.byte 0
mcu_output_byte:				;@ pointer in output buffer
	.byte 0
mcu_buffer:
	.space MCU_BUFFER_SIZE
	.space 2


;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
