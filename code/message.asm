;
; message.asm
;
; Created: 08.05.2018 16:56:25
; Author : Niccol? Stefanini & Gauzelin Vidovic

; ============================ MACROS ===============================

.macro 	MES_CHARCHECK		; @0 ascii code to data offset
	LDIZ	tldr
	cpi		@0, SPACE
	brne	testep
	ldi		@0, 0x00		; load space
	rjmp	ccheck_fin
testep:
	cpi		@0, ASCII_EP
	brne	testap
	ldi		@0, 0x02		; load !
	rjmp	ccheck_fin
testap:
	cpi		@0, ASCII_AP
	brne	testnum
	ldi		@0, 0x03		; load ''
	rjmp	ccheck_fin
testnum:
	cpi		@0, N0
	brlt	testletter
	cpi		@0, N9
	brge	testletter
	subi	@0, N0 - OF_NUM
	rjmp	ccheck_fin
testletter:
	cpi		@0, ASCII_A
	brlt	testlmin
	cpi		@0, ASCII_Z+1
	brge	testlmin
	subi	@0, ASCII_A - OF_LET
	rjmp	ccheck_fin
testlmin:
	cpi		@0, ASCII_am
	brlt	testqm
	cpi		@0, ASCII_zm+1
	brge	testqm
	subi	@0, ASCII_am
	LDIZ	tldr_min
	rjmp	ccheck_fin
testqm:
	ldi		@0, 1
ccheck_fin:
.endmacro


; subroutine to output a blank row on matrix (for spaces or end of transmission)
.macro	MES_OUTPUT_SPACE
	wdr					; reset watchdog timer
	WAIT_MS mes_t_shift
	SHIFT_DIS
	_LDI	d3, clear	; whiteline
	rcall	led_reverse_display
	lds		b3, b_n
	tst		b3			; check no new char in buffer
.endmacro

; =========================== ROUTINES ==============================


mode_message:			; full message mode routine (analyse UART transmission and display on matrix)
	sei
	ldi		w, 0x0f		; set colors
	mov		r2,w
	ldi		w, 0x00
	mov		r4,w
	ldi		w, 0x00
	mov		r5,w

	OUTI	UBRR0L, 0x33	; baud 4800 for 8 Mhz clock
	sbi		UCSR0B, RXEN0

	;rcall	led_clear_all
	CB_INIT

mes_t_serial_loop:		; wait loop
	wdr					; reset watchdog timer
	lds		b3, b_n		; check if letters in buffer
	tst		b3
	breq	mes_t_serial_loop
	WAIT_MS mes_t_shift
						; start of analyse process
	CB_POP		a3		; the letter is on the table
	MES_CHARCHECK	a3	; a3 now is the offset of table
	lsl			a3		; a3.6 because there is 6 bytes for each char in the lookup table
	mov			w,a3
	lsl			a3
	add			a3,w
	MUL2Z
	ADDZ		a3
	lpm			a2, z+
mes_sendout_loop:		; display a row of LEDs according to ASCII code
	wdr					; reset watchdog timer
	SHIFT_DIS
	lpm		d3, z+
	rcall	led_reverse_display
	dec		a2
	breq	mes_fin_affichage ; other letter other gift
	WAIT_MS mes_t_shift
	rjmp	mes_sendout_loop

mes_fin_affichage:		; output space between two characters
	MES_OUTPUT_SPACE
	breq	PC+2
	rjmp	mes_t_serial_loop

	ldi		b2,8
mes_fade_out:			; make the text exit the display when the transmission is finished
	MES_OUTPUT_SPACE
	brne	PC+3
	dec		b2
	brne	mes_fade_out
	rcall	led_color_shift
	rjmp	mes_t_serial_loop


; ============================ DATASEG ==============================


.dseg
b_in :	.byte 1 ; in pointer
b_out:	.byte 1 ; out pointer
b_n:	.byte 1 ; nombre d'?l?ments dans le buffer circulaire
buffer: .byte rx_len
.cseg

tldr:
.db 2,   0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000 \ ;  space
.db 4,   0b00000010, 0b01011001, 0b00001001, 0b00000110, 0b00000000 \ ;	 ?
.db 1,   0b01011111, 0b00000000, 0b00000000, 0b00000000, 0b00000000 \ ;  !
.db 1,	 0b00000011, 0b00000000, 0b00000000, 0b00000000, 0b00000000 \ ;  '
.db 4,   0b00111110, 0b01000001, 0b01000001, 0b00111110, 0b00000000 \ ;  0
.db 3,   0b01000010, 0b01111111, 0b01000000, 0b00000000, 0b00000000 \ ;  1
.db 4,   0b01100010, 0b01010001, 0b01001001, 0b01000110, 0b00000000 \ ;  2
.db 4,   0b00100010, 0b01000001, 0b01001001, 0b00110110, 0b00000000 \ ;  3
.db 4,   0b00011000, 0b00010100, 0b00010010, 0b01111111, 0b00000000 \ ;  4
.db 4,   0b00100111, 0b01000101, 0b01000101, 0b00111001, 0b00000000 \ ;  5
.db 4,   0b00111110, 0b01001001, 0b01001001, 0b00110000, 0b00000000 \ ;  6
.db 4,   0b01100001, 0b00010001, 0b00001001, 0b00000111, 0b00000000 \ ;  7
.db 4,   0b00110110, 0b01001001, 0b01001001, 0b00110110, 0b00000000 \ ;  8
.db 4,   0b00000110, 0b01001001, 0b01001001, 0b00111110, 0b00000000 \ ;  9
.db 4,   0b01111110, 0b00010001, 0b00010001, 0b01111110, 0b00000000 \ ;  A
.db 4,   0b01111111, 0b01001001, 0b01001001, 0b00110110, 0b00000000 \ ;  B
.db 4,   0b00111110, 0b01000001, 0b01000001, 0b00100010, 0b00000000 \ ;  C
.db 4,   0b01111111, 0b01000001, 0b01000001, 0b00111110, 0b00000000 \ ;  D
.db 4,   0b01111111, 0b01001001, 0b01001001, 0b01000001, 0b00000000 \ ;  E
.db 4,   0b01111111, 0b00001001, 0b00001001, 0b00000001, 0b00000000 \ ;  F
.db 4,   0b00111110, 0b01000001, 0b01001001, 0b01111010, 0b00000000 \ ;  G
.db 4,   0b01111111, 0b00001000, 0b00001000, 0b01111111, 0b00000000 \ ;  H
.db 3,   0b01000001, 0b01111111, 0b01000001, 0b00000000, 0b00000000 \ ;  I
.db 4,   0b00110000, 0b01000000, 0b01000001, 0b00111111, 0b00000000 \ ;  J
.db 4,   0b01111111, 0b00001000, 0b00010100, 0b01100011, 0b00000000 \ ;  K
.db 4,   0b01111111, 0b01000000, 0b01000000, 0b01000000, 0b00000000 \ ;  L
.db 5,   0b01111111, 0b00000010, 0b00001100, 0b00000010, 0b01111111 \ ;  M
.db 5,   0b01111111, 0b00000100, 0b00001000, 0b00010000, 0b01111111 \ ;  N
.db 4,   0b00111110, 0b01000001, 0b01000001, 0b00111110, 0b00000000 \ ;  O
.db 4,   0b01111111, 0b00001001, 0b00001001, 0b00000110, 0b00000000 \ ;  P
.db 4,   0b00111110, 0b01000001, 0b01000001, 0b10111110, 0b00000000 \ ;  Q
.db 4,   0b01111111, 0b00001001, 0b00001001, 0b01110110, 0b00000000 \ ;  R
.db 4,   0b01000110, 0b01001001, 0b01001001, 0b00110010, 0b00000000 \ ;  S
.db 5,   0b00000001, 0b00000001, 0b01111111, 0b00000001, 0b00000001 \ ;  T
.db 4,   0b00111111, 0b01000000, 0b01000000, 0b00111111, 0b00000000 \ ;  U
.db 5,   0b00001111, 0b00110000, 0b01000000, 0b00110000, 0b00001111 \ ;  V
.db 5,   0b00111111, 0b01000000, 0b00111000, 0b01000000, 0b00111111 \ ;  W
.db 5,   0b01100011, 0b00010100, 0b00001000, 0b00010100, 0b01100011 \ ;  X
.db 5,   0b00000111, 0b00001000, 0b01110000, 0b00001000, 0b00000111 \ ;  Y
.db 4,   0b01100001, 0b01010001, 0b01001001, 0b01000111, 0b00000000	\ ;  Z
tldr_min:
.db 4, 	 0b00100000, 0b01010100, 0b01010100, 0b01111000, 0b00000000 \ ; a
.db 4, 	 0b01111111, 0b01000100, 0b01000100, 0b00111000, 0b00000000 \ ; b
.db 4, 	 0b00111000, 0b01000100, 0b01000100, 0b00101000, 0b00000000 \ ; c
.db 4,   0b00111000, 0b01000100, 0b01000100, 0b01111111, 0b00000000 \ ; d
.db 4, 	 0b00111000, 0b01010100, 0b01010100, 0b00011000, 0b00000000 \ ; e
.db 3, 	 0b00000100, 0b01111110, 0b00000101, 0b00000000, 0b00000000 \ ; f
.db 4, 	 0b10011000, 0b10100100, 0b10100100, 0b01111000, 0b00000000 \ ; g
.db 4, 	 0b01111111, 0b00000100, 0b00000100, 0b01111000, 0b00000000 \ ; h
.db 3, 	 0b01000100, 0b01111101, 0b01000000, 0b00000000, 0b00000000 \ ; i
.db 4, 	 0b01000000, 0b10000000, 0b10000100, 0b01111101, 0b00000000 \ ; j
.db 4,	 0b01111111, 0b00010000, 0b00101000, 0b01000100, 0b00000000 \ ; k
.db 3, 	 0b01000001, 0b01111111, 0b01000000, 0b00000000, 0b00000000 \ ; l
.db 5, 	 0b01111100, 0b00000100, 0b01111100, 0b00000100, 0b01111000 \ ; m
.db 4, 	 0b01111100, 0b00000100, 0b00000100, 0b01111000, 0b00000000 \ ; n
.db 4, 	 0b00111000, 0b01000100, 0b01000100, 0b00111000, 0b00000000 \ ; o
.db 4, 	 0b11111100, 0b00100100, 0b00100100, 0b00011000, 0b00000000 \ ; p
.db 4, 	 0b00011000, 0b00100100, 0b00100100, 0b11111100, 0b00000000 \ ; q
.db 4, 	 0b01111100, 0b00001000, 0b00000100, 0b00000100, 0b00000000 \ ; r
.db 4,	 0b01001000, 0b01010100, 0b01010100, 0b00100100, 0b00000000 \ ; s
.db 3, 	 0b00000100, 0b00111111, 0b01000100, 0b00000000, 0b00000000 \ ; t
.db 4, 	 0b00111100, 0b01000000, 0b01000000, 0b01111100, 0b00000000 \ ; u
.db 5, 	 0b00011100, 0b00100000, 0b01000000, 0b00100000, 0b00011100 \ ; v
.db 5, 	 0b00111100, 0b01000000, 0b00111100, 0b01000000, 0b00111100 \ ; w
.db 5, 	 0b01000100, 0b00101000, 0b00010000, 0b00101000, 0b01000100 \ ; x
.db 4, 	 0b10011100, 0b10100000, 0b10100000, 0b01111100, 0b00000000 \ ; y
.db 3, 	 0b01100100, 0b01010100, 0b01001100, 0b00000000, 0b00000000 \ ; z
