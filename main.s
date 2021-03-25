#include <xc.inc>

extrn	Clock_Setup, Clock
extrn	Operation
extrn	LCD_Setup
extrn	Keypad, keypad_val
extrn	Alarm_Setup
extrn	ADC_Setup
  
global	Operation_Check
    
psect	udata_acs
operation_check:	ds  1	;reserving byte   
    
psect	code, abs
	
main:	org	0x0	; reset vector
	goto	start
	;org	0x100

int_hi:	org	0x0008	; high vector, no low vector
	goto	Clock
	
start:
	call	LCD_Setup
	call	Clock_Setup
	call	Alarm_Setup
	call	ADC_Setup
	
	clrf	operation_check, A
	
settings_clock:
	call	Keypad
	
	movlw	0x0f
	CPFSEQ	keypad_val, A
	bra	settings_clock
	
	call	Operation
	
	goto	settings_clock	; Sit in infinite loop
    
	end	main
