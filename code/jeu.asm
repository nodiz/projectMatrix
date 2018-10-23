;
; jeu.asm
;
; Created: 08.05.2018 16:56:25
; Author : Niccol� Stefanini & Gauzelin Vidovic

.dseg
	error_counter:	.byte	1
.cseg

mode_jeu:					; full game mode routine
		sei
		in		w,PIND		; wait loop
		cpi		w,0xff		; START if user presses any button
		brne	PC+2
		rjmp	mode_jeu

	   ; == BEGINNING ==	; set up a lookup table for the masks with X pointer ?

	    cli					; YOU CAN'T INTERRUPT THE GAME (SO IT DOESN'T MESS UP THE DISPLAYS & RYTHM)
		wdr					; reset watchdog timer
	    rcall	led_clear_all

		ldi		w, 0x10		; initialize display color to green (no error yet)
		mov		r2,w
		ldi		w, 0x00
		mov		r4,w
		mov		r5,w
		ldi		zl, low (2*(tetris))
		ldi		zh, high(2*(tetris))

		JEU_INIT c0			; load initial score
		JEU_INIT c1
		JEU_INIT c2
		JEU_INIT c3
		JEU_INIT d0
		JEU_INIT d1
		JEU_INIT d2
		JEU_INIT d3
		rcall	led_display_rgb

		ldi		zl, low (2*(tetris))	; load pointer to music score
		ldi		zh, high(2*(tetris))	; (we could instead use PUSH2 POP2, but it's not faster whatsoever)
		lds		w,error_counter			; initialze error counter to 0
		clr		w
		sts		error_counter,w
		WAIT_MS 1000		; wait for the user to release the button
jeu_play:					; loop for a single note
		wdr					; reset watchdog timer
		set					; initialize continue mark
		ser		a0			; initialize mistake flag

		movw	yl,zl		; PUSH2	zh,zl	?
		adiw	zl,7		; looking for next note to appear on screen
		lpm
		movw	zl,yl		; POP2	zh,zl	?

		mov		w ,r0
		ldi		_w,0xff		; default : outputs nothing if no tune
		cpi		w ,end		; is it the end of the music score ?
		breq	jeu_end_ini
		cpi		w ,ns		; is it "no sound" ?
		breq	jeu_end_ini	; ---> if yes : no mask to load

		LDMASK	_w,w		; create mask
jeu_end_ini:				; branch if no new note to display (blank)
		mov		d3,_w		; (can't use ldi with d3)
		rcall	led_display_rgb		; display current music score

		lpm					; load note to play
		mov		a2,r0		; move note to a2
		adiw	zl,1		; increment pointer z
		cpi		a2,end		; test end of file
		breq	jeu_victory_screen
		lsr		a2			; adjust the tune for 8 MHz instead of 4 MHz
		ldi		b0,bpm		; load play duration (50*2.5ms = 125ms)
		rcall	sound		; play the sound
		SHIFT_DIS			; prepare next display

		com		a0			; result analysis
		brne	jeu_error
		brts	jeu_error

		rjmp	jeu_play

;incrementation cyclique pour rd avec d<16
.macro _INC_CYC ; r, min, max
	mov w, @0
	INC_CYC w, @1, @2
	mov @0, w
.endmacro

jeu_victory_screen:			; loops on animation while changing colors
		sei
		LDIZ 	0x00
		_LDI  r2, 0
		_LDI  r4, 10
		_LDI  r5, 20
victory_loop:
		SHIFT_DIS
		lpm 	d3,z+
		WAIT_MS 50
		_INC_CYC r2, 0, 30
		_INC_CYC r4, 0, 30
		_INC_CYC r5, 0, 30
		led_display_rgb
		rjmp victory_loop


jeu_error:					; subroutine if player made a mistake
		mov		w,r2		; gradually shifts color from green to red
		subi	w,4
		CYCLIC	w,0x00,0x10
		mov		r2,w
		mov		w,r4
		ADDI	w,4
		CYCLIC	w,0x00,0x10
		mov		r4,w

		lds		w,error_counter
		inc		w
		sts		error_counter,w
		sbrs	w,2			; lose when w = 0b00000100 => "4 lives"
		rjmp	jeu_play	; continues w/ next note if more lives left
jeu_over:					; else, display mistake and reset game
		rcall	led_display_rgb
		WAIT_MS	100
		wdr					; reset watchdog timer
		in		w,PIND		; wait loop
		cpi		w,0xff		; RESET if user presses any button
		brne	PC+2
		rjmp	PC-4
		WAIT_MS	1000
		rcall	led_clear_all
		wdr					; reset watchdog timer
		rjmp	mode_jeu

; ------------------------------------------------------------------------------------------
