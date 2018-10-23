;
; projectMatrix.asm
;
; Created: 08.05.2018 16:56:25
; Author : Niccol� Stefanini & Gauzelin Vidovic

.include "macros.asm"		; include macro definitions
.include "definitions.asm"	; include register/constant definitions

; on aurait pu utiliser plus de macros afin d'am�liorer la lisibilit� du code (bcp de morceaux qu'on a �crit existent en macro !)
; simplement on n'avait pas consience de leur existance au moment du d�veloppement.
; "La transmission des bits est r�alis�e au moyen de macros plut�t que par des boucles afin de garantir des timings pr�cis" -> avrLED

; pages 28, 34-37 pour nettoyer l'utilisation des variables
; d�finir les appels des registres par des noms constants (changement plus facile)


; ==================================== interrupt table =====================================

	jmp	reset
.org	0x0a
	jmp	int_4	; PINE4..7
	jmp	int_5
	jmp	int_6
.org	0x24
	jmp uart_rxc


; ============================== interrupt service routines ================================

int_4:
int_5:	lds		a1,mode
		rcall	encoder			; TO DO :  correct interrupts (encoder)
		CYCLIC	a1,1,4			; rapport, page 72 polycop pour MACROS, 127 pour ROUTINES,
		sts		mode,a1	; CYCLIC prend des nombres entre 1 et 255 => n�cessiter d'incr�menter avant car on traite entre 0 et 3 sinon...
		dec		a1

		rcall	LCD_clear
		LCDPUTS	str0
		rcall	LCD_lf
		LCDPUTS str1

		rjmp	int_6_endLoad
int_6:	lds		a1,mode	; sale incoming, chercher � changer pour la table de sauts ?
		dec		a1
int_6_endLoad:
		wdr				; reset watchdog timer
		cbi		UCSR0B, RXEN0	; disable interrupt UART
		rcall	led_clear_all
		sbrc	a1,1
		rjmp	modes_23		; <=> PC+6 because jmp is 2 words long /!\
		sbrs	a1,0
		jmp		animation
		jmp		jeu
modes_23:
		sbrs	a1,0
		jmp		spectro
		jmp		message

uart_rxc:
		in _w, UDR0
		CB_PUSH _w
		reti



; =========================== constant chains & SRAM variables =============================					; move to definition.asm ?

.dseg								; SRAM variables
	mode:	.byte	1
.cseg

tetris:								; music score
.db		mi2,mi2,ns,si,ns,do2,ns,re2,re2,ns,do2,ns,si,ns,	la,la,ns,la,ns,do2,ns,mi2,mi2,ns,re2,ns,do2,ns		; odd number of bytes => padding
.db		si,si,ns,do2,do2,ns,re2,re2,ns,mi2,mi2,ns,			do2,do2,ns,la,la,ns,la,la,la,la,ns,					re2
.db		re2,ns,re2,fa2,la2,la2,ns,so2,ns,fa2,ns,			mi2,mi2,ns,mi2,ns,do2,ns,mi2,mi2,ns,re2,ns,do2,ns,	si
.db		si,ns,do2,do2,ns,re2,re2,ns,mi2,mi2,ns,				do2,do2,ns,la,la,ns,la,la,la,la,ns,end,				end,end,end,end,end,end,end

victory_anim:						; led patterns
.db		0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,			0x7f,0x3f,0x1f,0x0f,0x07,0x03,0x01,					0x00
.db		0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,			0xc0,0xe0,0xf0,0xf8,0xfc,0xfe
.db		0xff,0xff,0xff,0xff,0xff,0xff,0xff,eoc

									; menu display
str0:	.db	"ANIMATION    jeu","animation    JEU","animation    jeu","animation    jeu"
str1:	.db "spectro  message","spectro  message","SPECTRO  message","spectro  MESSAGE"

; ================================= initialization (reset) =================================

reset:	LDSP	RAMEND				; load SP
		rcall	LCD_init			; initialize the LCD
		OUTI	EIMSK, 0b01110000	; INT7..0
		OUTEI	EICRB, 0b00001010	; INT7..4

		OUTI	DDRB, 0xff			; output LEDs
		OUTI	PORTB,0xff			; turn off LEDs
		OUTI	DDRD, 0x00			; input switchers
		rcall	LCD_init			; initialize the LCD
		rcall	encoder_init		; initialize rotary encoder
		OUTI	DDRE,0b00000010		; make Tx (PE1) an output
		sbi		PORTE,PE1			; set Tx to high
		sbi		DDRE, SPEAKER		; initialize speaker				Sound -> sbi // Mute -> cbi
		sbi		UCSR0B, RXCIE0				; condenser l'?criture
		cbi		UCSR0B, UCSZ02
		ldi		w,(1<<UCSZ01)+(1<<UCSZ00)
		sts		UCSR0B, w				; 8-bit, 1 stop bit, parity disabled CHECK

		ldi		a1,0x01					; initialize mode value to 1
		sts		mode,a1
		dec		a1					; initialize encoder value to 0
		LCDPUTS	str0				; display default menu
		rcall	LCD_lf
		LCDPUTS str1

		wdr							; reset watchdog timer
		ldi		w,0x18				; watchdog enable procedure (Safety level 1)
		out		WDTCR, w
		ldi		w,0x0f
		out		WDTCR, w

		ldi		w, 0x0f				; load color for boot animation
		mov		r2,w
		mov		r4,w
		mov		r5,w
		rcall	anim_stand_by		; boot animation

		sei							; set global interrupt
		jmp		animation			; default mode


.include "encoder.asm"		; include rotary encoder routines
.include "lcd.asm"			; include the LCD routines
.include "printf.asm"		; include formated printing routines
.include "sound.asm"		; include sound routine
.include "avrLED.asm"		; include matrix routine
.include "animation.asm"	; include animation mode
.include "jeu.asm"			; include game mode
.include "spectro.asm"		; include spectrometer mode
.include "message.asm"		; include message mode

; ------------------------------------------------------------------------------------------

animation:
		LDSP	RAMEND		; Branch here w/ rcall but infinite loop => no ret => no use for all the prior infos on the stack
		rcall	mode_anim	;												   => free memory to avoid eventual saturation

; ------------------------------------------------------------------------------------------

jeu:
		LDSP	RAMEND
		rcall	mode_jeu

; ------------------------------------------------------------------------------------------

spectro:
		LDSP	RAMEND
		rcall	mode_spectro

; ------------------------------------------------------------------------------------------

message:
		LDSP	RAMEND
		rcall	mode_message

; ------------------------------------------------------------------------------------------
