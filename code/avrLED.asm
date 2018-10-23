;
; avrLED.asm
;
; Created: 08.05.2018 16:56:25
; Author : Niccolò Stefanini & Gauzelin Vidovic

;IN		c0,c1,c2,c3c,d0,d1,d2,d3	: 64 databits
;		r2,r4,r5					: 24 grb bits

;OUT	MAGIC

; ============================ MACROS ===============================

.equ	min_rgb	= 0x01				; >= 0x01
.equ	max_rgb	= 0x0c				; <= 0xfe



.macro	SEND0	; 1: 250us, 0: 800 us	/!\ 8 MHz CLOCK
		OUTI PORTB, 0xff
		OUTI PORTB, 0x00
;		nop (x6); to get the correct cycle, but the wait is already ensured by the rest of the program
.endmacro



.macro	SEND1	; 1: 750us, 0: 500 us
		OUTI PORTB, 0xff
		nop
		nop
		nop
		nop
		OUTI PORTB, 0x00
;		nop (x2)
.endmacro



.macro SEND_RGB	; outputs LSB of @0
		lsl		@0
		brcs	rgb_else
		SEND0
		rjmp	rgb_end
rgb_else:
		SEND1
rgb_end:
.endmacro



.macro LINE_OUT_RGB	; outputs full register @0 on the matrix, LSB out first
		mov		r0 ,@0
		ldi		_w,8
line_rgb_loop:
		lsr		r0
		brcs	PC+3			; brcSET because masks are inverted (initially made for the switchers, which have pull-up connection)
		rcall	led_rgb
		rjmp	line_rgb_else
		LED_CLEAR
line_rgb_else:
		dec		_w
		brne	line_rgb_loop
.endmacro



.macro LINE_OUT_REV ; outputs full register @0 on the matrix, MSB out first
		mov		r0 ,@0
		ldi		_w,8
		lsl		r0
line_rgb_loop:
		lsl		r0				; lsr
		brcC	PC+3
		rcall	led_rgb
		rjmp	line_rgb_else
		LED_CLEAR
line_rgb_else:
		dec		_w
		brne	line_rgb_loop
.endmacro




.macro LED_CLEAR	; clear one led
		PUSH3	r2,r4,r5
		ldi		w, 0x00
		mov		r2,w
		mov		r4,w
		mov		r5,w
		rcall	led_rgb
		POP3	r2,r4,r5
.endmacro


; ============================ ROUTINES ===============================

led_rgb:			; turns on one led with GBR parameters given by r2,r4,r5
		PUSH3		r2,r4,r5
   
		SEND_RGB	r2; G7
		SEND_RGB	r2; G6
		SEND_RGB	r2; G5
		SEND_RGB	r2; G4
		SEND_RGB	r2; G3
		SEND_RGB	r2; G2
		SEND_RGB	r2; G1
		SEND_RGB	r2; G0
		  
	
		SEND_RGB	r4; R7
		SEND_RGB	r4; R6
		SEND_RGB	r4; R5
		SEND_RGB	r4; R4
		SEND_RGB	r4; R3
		SEND_RGB	r4; R2
		SEND_RGB	r4; R1
		SEND_RGB	r4; R0
		

		SEND_RGB	r5; B7
		SEND_RGB	r5; B6
		SEND_RGB	r5; B5
		SEND_RGB	r5; B4
		SEND_RGB	r5; B3
		SEND_RGB	r5; B2
		SEND_RGB	r5; B1
		SEND_RGB	r5; B0
	
		POP3		r2,r4,r5
		ret



led_display_rgb:		; displays the registers c0...d3 on the matrix, with GBR bytes given by r2,r4,r5
		cli				; sends LSB out first
		LINE_OUT_RGB	c0
		LINE_OUT_RGB	c1
		LINE_OUT_RGB	c2
		LINE_OUT_RGB	c3
		LINE_OUT_RGB	d0
		LINE_OUT_RGB	d1
		LINE_OUT_RGB	d2
		LINE_OUT_RGB	d3
		sei
		ret



led_reverse_display:	; displays the registers c0...d3 on the matrix, with GBR bytes given by r2,r4,r5
		cli				; sends MSB out first
		LINE_OUT_REV	c0
		LINE_OUT_REV	c1
		LINE_OUT_REV	c2
		LINE_OUT_REV	c3
		LINE_OUT_REV	d0
		LINE_OUT_REV	d1
		LINE_OUT_REV	d2
		LINE_OUT_REV	d3
		sei
		ret



led_color_shift:		; shifts color within a given range (so it doesn't give out of control brightness)
		mov		w,r2
		ADDI	w,3
		CYCLIC	w,min_rgb,max_rgb
		mov		r2,w
		mov		w,r4
		subi	w,1
		CYCLIC	w,min_rgb,max_rgb
		mov		r4,w
		mov		w,r5
		subi	w,2
		CYCLIC	w,min_rgb,max_rgb
		mov		r5,w
		ret



led_clear_all:			; clears completly the matrix display
		cli
		ldi		_w,64
led_clear_loop:
		LED_CLEAR
		dec		_w
		brne	led_clear_loop
		WAIT_US	100
		sei
		ret



;	Old stuff, but has some rgb color codes 
/* led_clear:		; -Goz		1 = on, 0 = off, bits from 7...0
   ;Color	  ; Cl	Wh	Gr	Re	Bl	Ye	Pu	Or	...
	SEND0 ; G ;	0	0	1	0	0
	SEND0	  ; 0	0	1	0	0
	SEND0	  ; 0	0	1	0	0
	SEND0	  ; 0	0	1	0	0
	SEND0	  ; 0	1	1	0	0
	SEND0	  ; 0	1	1	0	0
	SEND0	  ; 0	1	1	0	0
	SEND0	  ; 0	1	1	0	0
	
	SEND0 ; R ; 0	0	0	1	0
	SEND0	  ; 0	0	0	1	0
	SEND0	  ; 0	0	0	1	0
	SEND0	  ; 0	0	0	1	0
	SEND0	  ; 0	1	0	1	0
	SEND0	  ; 0	1	0	1	0
	SEND0	  ; 0	1	0	1	0
	SEND0	  ; 0	1	0	1	0

	SEND0 ; B ; 0	0	0	0	1
	SEND0	  ; 0	0	0	0	1
	SEND0	  ; 0	0	0	0	1
	SEND0	  ; 0	0	0	0	1
	SEND0	  ; 0	1	0	0	1
	SEND0	  ; 0	1	0	0	1
	SEND0	  ; 0	1	0	0	1
	SEND0	  ; 0	1	0	0	1
	ret */