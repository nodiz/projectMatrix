; === routines ===

mode_spectro: ; initialize modalité spectrometer
	sei
	ldi		w, 0x00		; set colors
	mov		r2,w
	ldi		w, 0x03
	mov		r4,w
	ldi		w, 0x09
	mov		r5,w

	OUTI	UBRR0L, 0x33				; baud 4800 for 8 Mhz clock
	sbi		UCSR0B, RXEN0

	;rcall	led_clear_all
	CB_INIT
	clt


spe_t_serial_loop:
	wdr												; reset watchdog timer
	lds			b3, b_n 					; check if letters in buffer
	tst			b3
	breq		spe_t_serial_loop
	ldi			b1, 8
	CB_POP		a3							; the letter is on the table
	cpi			a3, SPACE
	brne		spe_t_serial_loop
	WAIT_US 	1000
spe_getFft:
	wdr													; reset watchdog timer
	lds			b3, b_n 						; check if letters in buffer
	tst			b3
	breq		spe_getFft
	CB_POP		a3
	subi		a3, N0
	LDIZ		fourier
	MUL2Z
	ADDZ		a3
	SHIFT_DIS
	lpm 		d3, z
	dec			b1
	brne 		spe_getFft
	rcall		led_display_rgb
	rjmp		spe_t_serial_loop

fourier: ; levels in fonction of d[0...8]
.db 0xff,0xfe,0xfc,0xf8,0xf0,0xe0,0xc0,0x80,0x00,0
