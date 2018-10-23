;
; macros.asm
;
; Created: 08.05.2018 16:56:25
; Author : Niccolò Stefanini & Gauzelin Vidovic

.macro	CYCLIC	;reg,lo,hi			(GOT MIDIFIED TO WORK WITH INCREMENTS BIGGER THAN ONE !)
	cpi		@0,@1				   ; UNSIGNED NUMBERS ONLY
	brsh	PC+2
	ldi		@0,@2
	cpi		@0,@2+1
	brlo	PC+2
	ldi		@0,@1
.endmacro

.macro 	LCDPUTS		; @0 string		; putstring of 16 characters on LCD
		ldi		zl, low (2*(@0))	; load pointer to string
		ldi		zh, high(2*(@0))
		ldi		w, 16
		mul		w, a1
		add		zl,r0
		rcall	LCD_putstring		; display string
	.endmacro

.macro	LDMASK		; @0 mask location,	@1 how to make the mask <=> ldi	@0,(1<<@1)
		andi	@1,0x07				; create flag
		ldi		@0,0x01
		tst		@1
		breq	PC+4
		lsl		@0
		dec		@1
		rjmp	PC-4
		com		@0
	.endmacro

.macro	JEU_INIT	; loads the next note to output in @0 when playing a song
		lpm
		ldi		_w,0xff
		tst		r0
		breq	PC+10				; jumps over macro
		mov		w ,r0		
		LDMASK	_w,w
		mov		@0,_w
		adiw	zl,1
	.endmacro

.macro	SHIFT_DIS	; shifts all the columns of the display, c0 will exit the matrix, and a new d3 will enter
	mov	c0,c1
	mov	c1,c2
	mov	c2,c3
	mov	c3,d0
	mov	d0,d1
	mov	d1,d2
	mov	d2,d3
	.endmacro

; =======================================
;			  CIRCULAR BUFFER
; =======================================

.macro CB_INIT				; initialize circular buffer and display
	ldi		w,0x00
	sts		b_in, w
	sts		b_out, w
	sts		b_n, w
	
	clr		c0
	clr		c1
	clr		c2
	clr		c3
	clr		d0
	clr		d1
	clr		d2
	clr		d3
.endmacro



.macro CB_PUSH				; push elem of the circular buffer to register @0
	PUSH2	a0,a1
	LDIZ	buffer
	lds		a0, b_in
	lds		a1, b_n
	inc		a1
	cpi		a1, rx_len		;TC
	breq	cb_fin_push
	ADDZ	a0
	st		z, @0
	INC_CYC	a0, 0, rx_len
	sts		b_in, a0
	sts		b_n, a1
cb_fin_push:	
	POP2	a0,a1
.endmacro



.macro CB_POP				; pop elem of the circular buffer to register @0
	LDIZ	buffer
	lds		a0, b_out
	lds		a1, b_n
	tst		a1				; cant give more
	breq	cb_fin_pop
	dec		a1
	ADDZ	a0
	ld		@0,z
	INC_CYC	a0, 0, rx_len
	sts		b_out, a0
	sts		b_n, a1
cb_fin_pop:	
.endmacro