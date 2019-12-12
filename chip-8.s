;-----------------------------------------------------------------------------
; BIOS
;-----------------------------------------------------------------------------

;	.org		0
;	.incbin		../bios.min		; don't need this for real PM

;-----------------------------------------------------------------------------
; Memory addresses
;-----------------------------------------------------------------------------

	.equ		tilemap			$1360	; default location for tilemap?

	.equ		BIOS_SIZE		$1000
	.equ		RAM_SIZE		$1000
	.equ		IO_SIZE			$0100
	.equ		ROM_SIZE		$80000

	.reloc
BIOS_BEGIN:		.ds		BIOS_SIZE
BIOS_END:
RAM_BEGIN:		.ds		RAM_SIZE
RAM_END:
IO_BEGIN:		.ds		IO_SIZE
IO_END:
USER_BEGIN:
	.endreloc

	.equ		NN				IO_BEGIN		; you can use [NN+...] instead of [nn+...] when required

;-----------------------------------------------------------------------------
; I/O address offsets
;-----------------------------------------------------------------------------

	.equ		BUTTONS			$52


	.equ		VIDEO_0			$80
	.equ		VIDEO_1			$81
	.equ		VIDEO_TILEDATA	$82		; word

	.equ		COUNTER2		$08

	.equ		CPU0			$00
	.equ		CPU2			$02

;-----------------------------------------------------------------------------
; I/O bits
;-----------------------------------------------------------------------------

	.equ		BUTTON_A		$01
	.equ		BUTTON_B		$02
	.equ		BUTTON_C		$04
	.equ		BUTTON_UP		$08
	.equ		BUTTON_DOWN		$10
	.equ		BUTTON_LEFT		$20
	.equ		BUTTON_RIGHT	$40
	.equ		BUTTON_POWER	$80

	.equ		CPU2_SPEED		$08

	.equ		COUNTER2_START	$01
	.equ		COUNTER2_RESET	$02
	
	.equ		VIDEO_0_INVERT	$01
	.equ		VIDEO_0_TILED	$02
	.equ		VIDEO_0_ENABLE0	$08
	.equ		VIDEO_0_TSIZE0	$10
	.equ		VIDEO_0_TSIZE1	$20

	.equ		VIDEO_1_ENABLE1	$01
	.equ		VIDEO_1_SLOW0	$02
	.equ		VIDEO_1_SLOW1	$04

;-----------------------------------------------------------------------------
; Interrupt numbers
;-----------------------------------------------------------------------------

	.equ	IntSuspend		0x21
	.equ	IntShutdown		0x24

;-----------------------------------------------------------------------------
; Header
;-----------------------------------------------------------------------------

	.org 0x2100
	.db		"MN"			; cam be anything except 0xBF,0xD9
	jmp		start

	.org 0x2108
	; interrupt handlers come here


	.org	0x21A4
	.db		"NINTENDO"		; magic string
	.db		"CHIP-8____"	; name
	.db		"CH-8"			; 4-character gamecode
	.db		"__"			; ?

;-----------------------------------------------------------------------------
; Start
;-----------------------------------------------------------------------------

	.equ C8_screen	$1000	; TODO change to middle of screen at some point

	; 1300–131F: sprite scratch 32 bits
	; 1320–1327: sprite scratch 16 bits

	.equ C8_I		$1338	; 1328–1329
	.equ C8_PC		$133A	; 132A–132B
	.equ C8_DT		$133C
	.equ C8_ST		$133D

	.equ C8_V		$1340	; V0–VF
	.equ C8_VF		C8_V + $F
	
	.equ C8_SP		$1350	; 1 byte offset for stack
	.equ C8_STACK	$1351	; TODO maybe 16 levels instead?
	.equ C8_ROM 	$1400	; TODO this can be changed to $135A after testing
	.equ C8_OFFSET	C8_ROM - $200 ; offset for CHIP-8 addresses

start:
	call	Init

	call CopyROMtoRAM

	mov hl, C8_ROM
	mov [C8_PC], hl
	mov a, 0
	mov [C8_SP], a

MainLoop:
	mov x, [C8_PC]
	mov h, [x]	; CHIP-8 programs are big-endian
	inc x
	mov l, [x]
	inc x
	mov [C8_PC], x

	mov a, h
	tst a, $FF
	jz opcode0

	and a, $F0
	xor a, $10
	jz opcode1

	mov a, h
	and a, $F0
	xor a, $20
	jz opcode2

	mov a, h
	and a, $F0
	xor a, $30
	jz opcode3

	mov a, h
	and a, $F0
	xor a, $40
	jz opcode4

	mov a, h
	and a, $F0
	xor a, $50
	jz opcode5

	mov a, h
	and a, $F0
	xor a, $60
	jz opcode6

	mov a, h
	and a, $F0
	xor a, $70
	jz opcode7

	mov a, h
	and a, $F0
	xor a, $80
	jz opcode8

	mov a, h
	and a, $F0
	xor a, $90
	jz opcode9

	mov a, h
	and a, $F0
	xor a, $A0
	jz opcodeA

	mov a, h
	and a, $F0
	xor a, $B0
	jz opcodeB

	mov a, h
	and a, $F0
	xor a, $C0
	jz opcodeC

	mov a, h
	and a, $F0
	xor a, $D0
	jz opcodeD

	mov a, h
	and a, $F0
	xor a, $E0
	jz opcodeE

	mov a, h
	and a, $F0
	xor a, $F0
	jz opcodeF

	;jmp		MainLoop

opcode0:
	mov a, l
	xor a, $E0
	jz opcode00E0

opcode00E0:
	;memCopy
	mov hl, $1000
_memCopyLoop:
	mov [hl], 0
	inc hl
	cmp l, $13
	jnz _memCopyLoop
	
	jmp MainLoop

opcode1:
	and h, $0F
	add hl, C8_OFFSET
	mov [C8_PC], hl
	jmp MainLoop

opcode2:
	jmp MainLoop

opcode3:
	mov b, 0
	mov a, l
	mov n, a
	mov a, h
	and a, $0F
	mov hl, C8_V
	add hl, ba
	mov a, n
	cmp a, [hl]
	jnz _notEqual

	mov x, C8_PC
	mov hl, [x]
	inc hl
	inc hl
	mov [x], hl

_notEqual:
	jmp MainLoop

opcode4:
	mov b, 0
	mov a, l
	mov n, a
	mov a, h
	and a, $0F
	mov hl, C8_V
	add hl, ba
	mov a, n
	cmp a, [hl]
	jz _equal

	mov x, C8_PC
	mov hl, [x]
	inc hl
	inc hl
	mov [x], hl

_equal:
	jmp MainLoop

opcode5:
	xchg ba, hl
	and b, $0F
	tst a, $0F
	jnz MainLoop
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	pop hl

	cmp a, b
	jnz _notEqual

	mov x, C8_PC
	mov hl, [x]
	inc hl
	inc hl
	mov [x], hl

_notEqual:
	jmp MainLoop

opcode6:
	mov b, 0
	mov a, l
	mov n, a
	mov a, h
	and a, $0F
	mov hl, C8_V
	add hl, ba
	mov a, n
	mov [hl], a
	jmp MainLoop

opcode7:
	mov b, 0
	mov a, l
	mov n, a
	mov a, h
	and a, $0F
	mov hl, C8_V
	add hl, ba
	mov a, n
	add [hl], a
	jmp MainLoop

opcode8:
	mov a, l
	tst a, $0F
	jz opcode8XY0

	and a, $0F
	mov b, a
	
	xor a, $01
	jz opcode8XY1

	mov a, b
	xor a, $02
	jz opcode8XY2

	mov a, b
	xor a, $03
	jz opcode8XY3
	
	mov a, b
	xor a, $04
	jz opcode8XY4
	
	mov a, b
	xor a, $05
	jz opcode8XY5

	mov a, b
	xor a, $06
	jz opcode8XY6
	
	mov a, b
	xor a, $07
	jz opcode8XY7
	
	mov a, b
	xor a, $0E
	jz opcode8XYE

	jmp MainLoop

opcode8XY0:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	pop a
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY1:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	or a, b
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY2:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	and a, b
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY3:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	xor a, b
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY4:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	add a, b
	mov [hl], a

	mov hl, C8_VF
	mov a, f
	shr a
	and a, $01
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY5:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	xchg a, b
	sub a, b
	mov [hl], a

	mov hl, C8_VF
	mov a, f
	shr a
	and a, $01
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY6:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	shr a
	mov [hl], a

	mov hl, C8_VF
	mov a, f
	shr a
	and a, $01
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XY7:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	sub a, b
	mov [hl], a

	mov hl, C8_VF
	mov a, f
	shr a
	and a, $01
	mov [hl], a

	pop hl

	jmp MainLoop

opcode8XYE:
	mov ba, hl
	and b, $0F
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	shl a
	mov [hl], a

	mov hl, C8_VF
	mov a, f
	shr a
	and a, $01
	mov [hl], a

	pop hl

	jmp MainLoop

opcode9:
	xchg ba, hl
	and b, $0F
	tst a, $0F
	jnz MainLoop
	swap a
	and a, $0F

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]

	pop a
	pop hl

	cmp a, b
	jz _equal

	mov x, C8_PC
	mov hl, [x]
	inc hl
	inc hl
	mov [x], hl

_equal:
	jmp MainLoop

opcodeA:
	and h, $0F
	add hl, C8_OFFSET
	mov [C8_I], hl
	jmp MainLoop

opcodeB:
	jmp MainLoop

opcodeC:
	jmp MainLoop

opcodeD:
	mov x, [C8_I]
	call CopySpriteToScreen
	jmp MainLoop

opcodeE:
	jmp MainLoop

opcodeF:
	jmp MainLoop

;-----------------------------------------------------------------------------
; Delay
;-----------------------------------------------------------------------------

Delay:
	push	x
	mov		x, 0
_loop:

	test	[nn+BUTTONS], BUTTON_POWER
	jnz		_dont_suspend
	int		IntSuspend
_dont_suspend:

	dec		x
	jnz		_loop
	pop		x
	ret

;-----------------------------------------------------------------------------
; Init
; init display to blit mode
;-----------------------------------------------------------------------------

Init:
	movw	nn, IO_BEGIN

	movb	[nn+VIDEO_0], $01+$08	# set blit mode
	movb	[nn+VIDEO_1], $01+$08	# enable video

	ret

CopyROMtoRAM:
	mov x, gameROM
	mov y, C8_ROM
	mov hl, endGameROM - gameROM
_loop:
	mov [y], [x]
	inc x
	inc y
	dec hl
	jnzb _loop

	ret

;-----------------------------------------------------------------------------
; CopySpriteToScreen
; display sprite from x
;-----------------------------------------------------------------------------

RotateSprite:
	push hl
	;memCopy
	mov b, l
	and b, $0F
	mov hl, $1310
_memCopyLoop:
	mov [hl], [x]
	inc hl
	inc x
	jdbnz _memCopyLoop

	pop hl
	push hl

	mov x, $1317
	mov hl, $1300
	mov n, 8
_sprite_row_loop:
	mov		b, 8
_sprite_bit_loop:
	mov a, [x]
	shl a
	mov [x], a
	rolc [hl]
	inc hl
	jdbnz _sprite_bit_loop

	dec x
	sub hl, 8
	dec n
	jnz _sprite_row_loop

	cmp x, $1317
	jz _done

	mov x, $131F
	mov hl, $1308
	mov n, 8
	jmp _sprite_row_loop

_done:
	pop ba
	ret

DoSpriteAttributeStuff:
	and b, $0F
	;mov n, a
	swap a
	and a, $0F

	; B X
	; A Y

	push b

	mov hl, C8_V
	mov b, l
	add a, b
	mov l, a
	mov a, [hl]
	and a, $1F

	mov h, a
	and h, $07
	
	; H is now bit offset/counter

	pop b
	push hl
	push a

	mov hl, C8_V
	mov a, l
	add a, b
	mov l, a
	mov b, [hl]
	and b, $3F

	pop a
	pop hl

	shr a
	shr a
	shr a

	xchg ba, hl

	; B is now bit offset/counter
	; HL is XY

	;mov a, n
	;and a, $0F
	;mov n, a

	; N is now row counter TODO not actually needed

	; get bit offset, Y AND 7: B
	; display row counter: N

	ret

OffsetSprite:

	; OK now we push HL so we can retrieve it as XY later
	push hl

	; TODO save N???

	; and try to do this

	; byte 0 = hl
	; byte 1 = x
	; byte 2 = y
	; for 8 bytes:
	;	for bit offset > 0:
	;		shift byte 0 left
	;		rolc byte 1
	;		rolc byte 2
	;		dec bit offset
	;	inc byte 0
	;	inc byte 1
	;	inc byte 2

	mov hl, $1300
	mov x, $1308
	mov y, $1310

	push ba

	tst b, $FF
	jz loop_done

	mov n, 8
	
for_bit_offset_lt_zero:
	shl [hl]
	mov a, [x]
	rolc a
	mov [x], a
	mov a, [y]
	rolc a
	mov [y], a
	jdbnz for_bit_offset_lt_zero

	dec n
	jz loop_done

	pop ba
	push ba
	inc hl
	inc x
	inc y
	jmp for_bit_offset_lt_zero

loop_done:
	pop ba
	pop hl

	ret


CopySpriteToScreen:

	mov y, C8_VF
	mov [y], 0

	; here:
	; x = sprite
	; hl = DXYN

	call RotateSprite

	; here:
	; $1300 = rotated sprite
	; ba = DXYN

	call DoSpriteAttributeStuff

	; $1300 = rotated sprite
	; B = offset

	call OffsetSprite

	; here:
	; $1300 = rotated and offset sprite

	xchg ba, hl
	mov l, 96
	mul l, a
	mov a, l
	add a, b
	mov l, a
	mov a, h
	add a, $10
	mov h, a

	;memCopy
	mov b, 8
	mov n, 3
	mov x, $1300
_memCopyLoop2:
	mov a, [x]
	and a, [hl]
	jz _noCollision

	mov y, C8_VF
	mov [y], 1

_noCollision:
	xor [hl], [x] ; TODO xor
	inc hl
	inc x
	jdbnz _memCopyLoop2
	dec n
	jz memcpy_done
	add hl, 88
	mov b, 8
	jmp _memCopyLoop2

memcpy_done:
	ret


;-----------------------------------------------------------------------------
; Data
;-----------------------------------------------------------------------------

	.align	8
font8x8:
	.incbin font8x8.bin

gameROM:
	.incbin test_opcode.ch8
endGameROM:

;-----------------------------------------------------------------------------
; End
;-----------------------------------------------------------------------------

	.end
