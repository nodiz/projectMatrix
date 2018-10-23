encoder_rot:
	sbrs	_u,ENCOD_A
	ret
	sbrs	_u,ENCOD_B
	ret

	sbrc	_w,ENCOD_A
	rjmp	a_rise
a_fall:						; _wA = 1
	inc		a1				; if B=1 then increment
	sbrs	_w,ENCOD_B
	subi	a1,2			; if B=0 then decrement
	ret
a_rise:						; _wA = 0
	inc		a1				; if B=0 then increment
	sbrc	_w,ENCOD_B
	subi	a1,2			; if B=1 then decrement
	ret

; DOESN'T SEEM TO WORK FOR WHAT WE WANT TO DO (GARBAGE)

; ----------------------------------------------------------------------------

;C_TBL	a2,labjmp						WTF OUTPUT, clears LCD and fucks up the display when rotating button...
;reti

;labjmp:	.db animation,jeu,spectro,message

; ----------------------------------------------------------------------------

;sortie sonore à l'appui ? plus simple que faire jouer mélodie (en terme de rythme)

		ldi		a3,0		; Comment gérer la sortie sonore à l'appui, interrupt modifierai durées + PIND 0..3 seulement...
eighth_note:				; Jouer par défaut ? Possibilité d'envoyer requête au buzzer puis continuer sans attendre fin son ?
		; Output notes on LEDs
		ldi		b0,0x00		; DON'T USE C because it is affected by cpi -> regular register instead with ldi 0 or 1...
		clt
		ldi		a2,0xff		; déterminer durée nécessaire
button_analysis:			; COMPTER LE NOMBRE DE CYCLES DE CHAQUE OPERATION
		in		r16,PIND	; 1+1 + 1+(1ou2,ici1)+1+2 + 1+(1ou2,ici2)+1 + ...
		dec		a2

		cpi		r16,		; mask from a lookup_table
		brne	PC+4
		set					; add nop if necessary !
		nop
		rjmp	PC+4

		cpi		r16,0xff	; no button pressed
		breq	PC+2
		ldi		b0,0x01		; will be avoided if buttons = MASK or 0

; --------------------------

		cpi		a2,0x00
		breq	PC+2
		rjmp	button_analysis

		cpi		b0,0x01
		breq	jeu_loop
		brtc	jeu_loop

		inc		a3
		cpi		a3,38		; nb notes tot, à changer si on rajoute des blancs
		brne	eighth_note
		rjmp	victory_screen

; ----------------------------------------------------------------------------

tetris:
.db		mi2,si,do2,re2,si,do2,		la,la,do2,mi2,re2,do2
.db		si,do2,re2,mi2,				do2,la,la,0
.db		re2,re2,fa2,la2,so2,fa2,	mi2,mi2,do2,mi2,re2,do2
.db		si,do2,re2,mi2,				do2,la,la,0	

; ----------------------------------------------------------------------------

;lsr		a2
;sbrs		a2,7		; test la2
;inc		a2			; adjust the tone

; ----------------------------------------------------------------------------

wait9us:rjmp	PC+1		; waiting 2 cycles
		rjmp	PC+1		; waiting 2 cylces
wait8us:rcall	wait4us		; recursive call with "falling through"
wait4us:rcall	wait2us	
wait2us:nop
		ret					; rcall(4), nop(1), ret(3) = 8cycl. (=2us)

; ----------------------------------------------------------------------------

play:
		set;clt	god mode				; initialize continue mark
		ldi		b2,0		; initialize mistake flag

		lpm					; load note to play
		mov		a2,r0		
		tst		a2
		breq	end_ini		
		LDMASK	b3,a2		; create mask
		OUT	PORTB, b3
		mov		a2,r0		; move note to a2

end_ini:
		adiw	zl,7		; increment pointer z
		lpm
		tst		a2			; put 7 EOF at the end
		breq	no_refresh
		mov		r28,r0
		LDMASK	r29,r28		; create mask for next OUTPUT
		; LEDoutput
		; LEDkeepOld
no_refresh:
		adiw	zl,-6		; decrement pointer z on next value tst

		inc		a2			; so no_sound isn't considered as end of script
		tst		a2			; test end of file (NUL)
		breq	victory_screen
		dec		a2			; restore original value (remember inc)						
		ldi		b0,160		; load play duration (50*2.5ms = 125ms)		ADAPTER
		rcall	sound		; play the sound

		tst		b2			; result analysis
		brne	jeu_loop
		brtc	jeu_loop

		rjmp	play

; ---- START WITH 8 ns ? ---- 0 (CURRENT), 1 (NEXT), 2, 3, 4, 5, 6, 7 (NEW) ----
; ---- Zl + 7, OUTPUT ON LEDS NEW TONE ------ Zl - 6, TO GET BACK TO NEXT ------

