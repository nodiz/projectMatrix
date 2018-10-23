; file:	sound.asm   target ATmega128L-4MHz-STK300
; purpose library, sound generation

sound:
; in	a2	period of oscillation (in 10us)
; 		b0	duration of sound (in 2.5ms)

	mov		b1,b0			; duration high byte = b
	clr		b0				; duration  low byte = 0
	clr		a3				; period high byte = a
	tst		a2
	breq	sound_off		; if a2=0 then no sound	
sound1:
	mov		b2,a2		
	rcall	button_analysis	; rcall	wait9us
	nop						; 0.25us
	dec		b2				; 0.25us
	brne	PC-3			; 0.50us	total = 10us
	INVP	PORTE,SPEAKER	; invert piezo output
	sub		b0,a2			; decrement duration low  byte
	sbc		b1,a3			; decrement duration high byte
	brcc	sound1			; continue if duration>0
	ret

sound_off:
	ldi		a2,1
	WAIT_MS	10
	sub		b0,a2			; decrement duration low  byte
	sbc		b1,a3			; decrement duration high byte
	brcc	PC-2			; continue if duration>0
	clt
	ret

; === wait routines ===

button_analysis:			; analyse the button input when a wait loop is needed
		in		w,PIND		
		cp		w,c0		
		brne	PC+4
		clt					
		nop
		rjmp	PC+4

		cpi		w,0xff		; no button pressed
		breq	PC+2
		clr		a0			; will be avoided if buttons = MASK or 0
							; total 7 cycles
		WAIT_US 4			; with these 2 instructions + rcall, ret : 18 cycles
		ret					; by calling it twice, we wait 9us !

; === calculation of the musical scale ===
 
; period (10us)	= 100'000/freq(Hz)
.equ	do	= 100000/517	; (517 Hz)
.equ	dom	= do*944/1000	; do major
.equ	re	= do*891/1000
.equ	rem	= do*841/1000	; re major
.equ	mi	= do*794/1000
.equ	fa	= do*749/1000
.equ	fam	= do*707/1000	; fa major
.equ	so	= do*667/1000
.equ	som	= do*630/1000	; so major
.equ	la	= 0b11100111	; do*595/1000
.equ	lam	= do*561/1000	; la major
.equ	si	= 0b11001110	; do*530/1000

.equ	do2	= 0b11000101	; do/2
.equ	dom2	= dom/2
.equ	re2	= 0b10101100	; re/2
.equ	rem2	= rem/2
.equ	mi2	= 0b10011011	; mi/2
.equ	fa2	= 0b10010010	; fa/2
.equ	fam2	= fam/2
.equ	so2	= 0b10000001	; so/2
.equ	som2	= som/2
.equ	la2	= 0b01110000	; la/2
.equ	lam2	= lam/2
.equ	si2	= si/2

.equ	do3	= do/4
.equ	dom3	= dom/4
.equ	re3	= re/4
.equ	rem3	= rem/4
.equ	mi3	= mi/4
.equ	fa3	= fa/4
.equ	fam3	= fam/4
.equ	so3	= so/4
.equ	som3	= som/4
.equ	la3	= la/4
.equ	lam3	= lam/4
.equ	si3	= si/4	

.equ	ns  = 0
.equ	end = 0xff
.equ	bpm = 80*2