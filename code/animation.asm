;
; animation.asm
;
; Created: 08.05.2018 16:56:25
; Author : Niccolò Stefanini & Gauzelin Vidovic

 mode_anim:		; full animation routine,	beginning of Tetris track
	    sei
		ldi		w, 0x04
		mov		r2,w
		ldi		w, 0x07
		mov		r4,w
		ldi		w, 0x0c
		mov		r5,w

		ldi		zl, low (2*(tetris))
		ldi		zh, high(2*(tetris))
		JEU_INIT c0
		JEU_INIT c1
		JEU_INIT c2
		JEU_INIT c3
		JEU_INIT d0
		JEU_INIT d1
		JEU_INIT d2
		JEU_INIT d3
		rcall	led_display_rgb

		ldi		zl, low (2*(tetris))	; load pointer to music score
		ldi		zh, high(2*(tetris))
anim_play:
		wdr					; reset watchdog timer
		rcall	led_color_shift
		movw	yl,zl		; PUSH2	zh,zl	would work too
		adiw	zl,7
		lpm		
		movw	zl,yl		; POP2	zh,zl	would work too

		mov		w ,r0		
		ldi		_w,0xff		; outputs nothing if no tune	
		cpi		w ,end
		breq	anim_end_ini
		cpi		w ,ns
		breq	anim_end_ini

		LDMASK	_w,w		; create mask
anim_end_ini:
		mov		d3,_w
		rcall	led_display_rgb

		lpm					; load note to play
		mov		a2,r0		; move note to a2
		adiw	zl,1		; increment pointer z
		inc		a2			; so no_sound isn't considered as end of script
		tst		a2			; test end of file (NUL)
		breq	anim_end
		dec		a2			; restore original value (remember inc)	
		lsr		a2			; adjust the tune for 8 MHz instead of 4 MHz					
		ldi		b0,bpm/2	; load play duration, twice as fast as game mode !
		rcall	sound		; play the sound
		SHIFT_DIS			; prepare display
		
		rjmp	anim_play
anim_end:					; end of music track, infinite loop on second animation
		rcall	led_color_shift
		rcall	anim_stand_by
		rjmp	anim_end

; ---------------------------------------------------------------------------

anim_stand_by:				; second animation
		ldi		zl, low (2*(victory_anim))
		ldi		zh, high(2*(victory_anim))
		ldi		a3,8
anim_standBy_iLoop:
		lpm					; initialize display
		mov		d3,r0
		SHIFT_DIS
		adiw	zl,1
		dec		a3
		brne	anim_standBy_iLoop
		rcall	led_display_rgb
		ldi		a3,eoc		; end of chain
anim_standBy_mLoop:
		WAIT_MS	100			; shifts lines to make it move
		wdr					; reset watchdog timer
		lpm
		cp		r0,a3		; test if end of chain
		breq	anim_standBy_end
		mov		d3,r0
		adiw	zl,1
		rcall	led_display_rgb
		SHIFT_DIS
		rjmp	anim_standBy_mLoop
anim_standBy_end:
		ret