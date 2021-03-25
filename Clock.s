#include <xc.inc>
	
extrn	Write_Time, Write_Temp
extrn	LCD_Set_to_Line_1, LCD_Set_to_Line_2, LCD_Write_Character, LCD_Write_Hex
extrn	Write_Decimal_to_LCD  
extrn	keypad_val
extrn	operation_check
extrn	Temp
extrn	Keypad
    
extrn	Check_Alarm

    
global	clock_sec, clock_min, clock_hrs
global	Clock, Clock_Setup, rewrite_clock
global	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null  
global	check_60, check_24, skip_byte    
    
psect	udata_acs
clock_hrs: ds 1
clock_min: ds 1
clock_sec: ds 1
    
check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex

timer_start_value_1:	ds 1
timer_start_value_2:	ds 1

hex_A:	ds 1
hex_B:	ds 1
hex_C:	ds 1
hex_D:	ds 1
hex_E:	ds 1
hex_F:	ds 1
hex_null:   	ds  1
    
skip_byte: ds 1

psect	Clock_timer_code, class=CODE

Clock_Setup: 
	movlw	0x00		;setting start time to 00:00:00
	movwf   clock_sec, A
	movwf   clock_min, A
	movwf   clock_hrs, A
	
	;Temp Port A setup
	;bcf	TRISA, 3
	
	bsf	skip_byte, 0, A
	
	call	rewrite_clock
	
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	movwf	check_60, A
	movlw	0x18
	movwf	check_24, A
	
	movlw	0x0A		;storing keypad character hex values
	movwf	hex_A, A
	movlw	0x0B
	movwf	hex_B, A
	movlw	0x0C
	movwf	hex_C, A
	movlw	0x0D
	movwf	hex_D, A
	movlw	0x0E
	movwf	hex_E, A
	movlw	0x0F
	movwf	hex_F, A
	movlw	0xff
	movwf	hex_null, A
	
	movlw	0x0B
	movwf	timer_start_value_1, A
	movlw	0xDB
	movwf	timer_start_value_2, A
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	
	return
    
Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	clock_inc	; increment clock time
	movff	timer_start_value_1, TMR0H	;setting upper byte timer start value
	movff	timer_start_value_2, TMR0L		;setting lower byte timer start value
	bcf	TMR0IF		; clear interrupt flag
	btfss	operation_check, 0, A ;skip rewrite clock if = 1
	call	rewrite_clock	;write and display clock time as decimal on LCD 
	call	Check_Alarm
	retfie	f		; fast return from interrupt	

rewrite_clock:
	call	LCD_Set_to_Line_1
	call	Write_Time	    ;write 'Time: ' to LCD
	movf	clock_hrs, W, A	    ;write hours time to LCD as decimal
	call	Write_Decimal_to_LCD  
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	movf	clock_min, W, A	    ;write minutes time to LCD as decimal
	call	Write_Decimal_to_LCD
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character
	movf	clock_sec, W, A	    ;write seconds time to LCD as decimal
	call	Write_Decimal_to_LCD
	call  LCD_Set_to_Line_2
	call	Write_Temp	    ;write 'Temp: ' to LCD
	call	Temp		    ;Here will write temperature to LCD
	return
	

clock_inc:	
	incf	clock_sec, A	    ;increase seconds time by one
	movf	clock_sec, W, A	   
	cpfseq	check_60, A	    ;check clock seconds is equal than 60
	return			    ;return if not equal to 60
	clrf	clock_sec, A	    ;set second time to 0 if was equal to 60
	incf	clock_min, A	    ;increase minute time by one
	movf	clock_min, W, A
	cpfseq	check_60, A	    ;check if minute time equal to 60
	return
	clrf	clock_min, A	    ;set minute time to 0 if = 60
	incf	clock_hrs, A	    ;increase hour time by one
	movf	clock_hrs, W, A	
	cpfseq	check_24, A	    ;check if hour time equal to 24
	return	
	clrf	clock_hrs, A	    ;set hour time to 0 if = 24
	return



