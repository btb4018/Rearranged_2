#include <xc.inc>
    
extrn	LCD_Set_Position 
    
    
global	alarm_on
global	alarm_sec, alarm_min, alarm_hrs 
global	Check_Alarm, Alarm_Setup
    
psect	udata_acs
alarm_sec:	ds  1
alarm_min:	ds  1
alarm_hrs:	ds  1
    
alarm_on:	ds  1
    
buzz_bit: ds	1
    
buzzer_counter_1: ds 1
buzzer_counter_2: ds 1
    
alarm_buzz: ds 1    
    
skip_byte: ds 1

psect	Alarm_code, class=CODE
    
Alarm_Setup:
	movlw	0x00	;;;;;
	movwf	alarm_sec, A
	movwf	alarm_min, A
	movwf	alarm_hrs, A
	
	bcf	alarm_on, 0, A
	bcf	buzz_bit, 0, A  
	
	clrf	Alarm_buzz, A
	
	return
    
Check_Alarm:
	movlw	0x00
	cpfseq	Alarm_buzz		;check if alarm_buzz has reached 0
	bra	decrement_alarm_buzz	;keep decrementing and buzzing if it hasn't
	bra	compare_alarm		;go to compare alarm and return to normal cycles if it has reached 0

decrement_alarm_buzz:
	decf	Alarm_buzz		;subroutine to keep decrementing alarm_buzz
	call	ALARM			;and buzzing
	return
	
;try instead of line 120-129?
;	decfsz	alarm_buzz
;	BNN	ALARM
;	BRA	Compare_Alarm
	
Compare_Alarm:				;compare alarm
	btfss	alarm_on, 0, A		;check if alarm is on
	return				;return if it isnt on
	movf	alarm_hrs, W, A			;otherwise compare clock time to alarm time
	CPFSEQ	clock_hrs, A	
	return
	movf	alarm_min, W, A	
	CPFSEQ	clock_min, A	
	return
	movf	alarm_sec, W, A	
	CPFSEQ	clock_sec, A	
	return			    ;return if not the same
	
	movlw	0x3C
	movwf	alarm_buzz, A	    ;set alarm_buzz to 60 to be able to buzz for 60 seconds
	    
	call	ALARM		    ;call alarm if it is the same
	return
ALARM:
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	Display_ALARM	    ;display alarm while alarm is ringing
	
	call	check_buzz_bit	    ;check the buzz_bit to set it if it was clear and to clear it if it was set
	;BTG	buzz_bit, 0
	
	call	Buzzer		    ;call buzzer which buzzes when the buzz_bit is set

	return	
		
check_buzz_bit:
	btfsc	buzz_bit, 0, A			;check if buzz bit is set
	bra	clear_buzz_bit		;branch to set it if it isnt set
	bra	set_buzz_bit		;branch to clear it if it is set
clear_buzz_bit:	
	bcf	buzz_bit, 0, A			;clear buzz_bit 
	return
set_buzz_bit:
	bsf	buzz_bit, 0, A			;set buzz_bit
	return
	
Buzzer:	
	;Initialize
	bcf	TRISB, 6, A			;set RB6 to output
	
	movlw	0x64
	movwf	buzzer_counter_1, A		;values for buzzer counter that counts down a second and buzzes at every count
	movlw	0x1E
	movwf	buzzer_counter_2, A		;	"

Buzz_Loop_1:
Check_Cancel_Snooze:
	call	Keypad
	movf	keypad_val, W, A	
	CPFSEQ	hex_C, A	
	btfss	skip_byte, 0, A	
	bra	Cancel_Alarm
	CPFSEQ	hex_A, A	
	btfss	skip_byte, 0, A	
	bra	Snooze_Alarm
	
	call	Buzz_Loop_2		;call second loop at every count, nested loops
	movlw	0x1E
	movwf	buzzer_counter_2, A		;reset count down value for second loop
	
	decfsz	buzzer_counter_1, A		;decrease till 0 and skip when 0
	bra	Buzz_Loop_1
	return		
Buzz_Loop_2:
	call	Buzz_Sequence		;buzz at every count
	decfsz	Buzzer_Counter_2, A	
	bra	Buzz_Loop_2
	return

Buzz_sequence:	
Check_if_Buzz:
	btfss	buzz_bit, 0, A	
	bra	No_Buzz
	bra	Yes_Buzz
No_Buzz: 
	call	Delay_Buzzer
	call	Delay_Buzzer
	return
Yes_Buzz:	
	bsf	LATB, 6	;Ouput high
	call	Delay_Buzzer
	bcf	LATB, 6	;Ouput low
	call	Delay_Buzzer
	return	
    
Delay_Buzzer:
	movlw	0x20	    ;half the time period long delay
	call	LCD_delay_x4us
	return

Cancel_Alarm:
	clrf	alarm_buzz, A	
	return
	
Snooze_Alarm:
	clrf    alarm_buzz, A	
	call	Write_Snooze
	movlw	0x05
	addwf	alarm_min, A	
	movlw	0x3B
	CPFSGT	alarm_min, A	
	return
	movlw	0x3C
	subwf	alarm_min, 1, 0
	incf	alarm_hrs, A	
	movlw	0x17
	CPFSGT	alarm_hrs, A	
	return
	movlw	0x18
	subwf	alarm_hrs, 1, 0
	return

end
