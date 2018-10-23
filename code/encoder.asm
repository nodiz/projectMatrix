; file	encoder.asm   target ATmega128L-4MHz-STK300
; purpose library angular encoder operation

; === definitions ===
.equ	ENCOD	= PORTE

.dseg
enc_old:	.byte 1
.cseg

; ==================== routines =================

encoder_init:
	in		w,ENCOD-1		; make 3 lines input
	andi	w,0b10001111
	out		ENCOD-1,w
	in		w,ENCOD			; enable 3 internal pull-ups
	ori		w,0b01110000
	out		ENCOD,w
	ret

encoder:
	clt						; preclear T
	in		_w,ENCOD-2		; read encoder port (_w=new)
	andi	_w,0b01110000	; mask encoder lines (A,B,I)
	lds		_u, enc_old		; load prevous value (_u=old)
	cp		_w,_u			; compare new<>old ?
	brne	PC+2
	ret						; if new=old then return
	sts		enc_old, _w		; store encoder value for next time

	sbrc	_u,ENCOD_I
	rjmp	encoder_rot
	sbrc	_w,ENCOD_I
	set

encoder_rot:
	sbrs	_u,ENCOD_A
	rjmp	countercw
	sbrc	_u,ENCOD_B
	ret
	sbrc	_w,ENCOD_A
	ret
	sbrc	_w,ENCOD_B
	inc		a1
	ret
countercw:
	sbrs	_u,ENCOD_B
	ret
	sbrs	_w,ENCOD_A
	ret
	sbrs	_w,ENCOD_B
	dec		a1
	ret
