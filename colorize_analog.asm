 list	R=DEC
;*******************************************************************************
;
; Program: WS2813
; Author: Paul Wood
; Date Created: 06/30/2018 5:40PM
; Purpose: To display patterns on WS2813 based RGB LED strip
;
;*******************************************************************************
;
; Program Hierarchy:
;
;
;*******************************************************************************
;				  EXTERNALS
;*******************************************************************************
#include p16f1615.inc
#include WS2813.inc
#include UtilMacros.inc
    
    GLOBAL  DO_RENDER
    GLOBAL  EXTERN_INTERRUPT_SERV
    GLOBAL  EXTERN_INITIAL


;*******************************************************************************
;			      MACRO DEFINITIONS
;*******************************************************************************
ACQ_DELAY   MACRO
   MOVLW    0x0E
ACQ:
    DECFSZ  WREG, W
    GOTO    ACQ
   ENDM
 
WITHIN_TRIGGER	MACRO	D	    ; sets C flag of STATUS register
	BCCZ			    ; clear Z and C flags
	CMP16	TGRL, D		    ; test if above lower trigger - C will be clear
	BTFSC	STATUS, C	    ; exits macro if C set = not above TGRL
	GOTO	$+6
	CMP16	TGRH, D		    ; will set c if below TGRH
	ENDM
   
;*******************************************************************************
;			    VARIABLE DEFINITIONS
;*******************************************************************************
    #DEFINE ADC_CH	AN3	    ; RA4
    #DEFINE ADC_TRIS	TRISA4
    #DEFINE ADC_ANSEL	ANSA4
    #DEFINE TRIGGER_OFF	0x3F	    ; 10bit resolution  [0V, 5V] corresponds to [0x000, 0x3FF]
				    ; TRIGGER_OFF = 0.5V -> 5V / 10 -> 0x3FF / 10
    
    UDATA   0x20
;ADC REGISTER
WDATA	RES 2		    ; copied data from ADC read
    
;AMPLITUDE REGISTERS
AMPL	RES 2		    ; calculated amplitude 
MIN_WAV	RES 2		    ; wave trough
MAX_WAV	RES 2		    ; wave peak
	
;FREQUENCY REGISTERS
DELTA_T	RES 2		    ; change in timer3 ticks from 2 tiggered plots
TGRH	RES 2;EQU 0x1FF + TRIGGER_OFF	    ; signal coming in biased to 2.5V w/ range [0V, 5V] 
TGRL	RES 2;EQU 0x1FF - TRIGGER_OFF	    ; 2.5V corresponds to 0x3FF / 2 = 0x1FF
 
    
    CODE	0x1800
;*******************************************************************************
;				EXTERN_INITIAL
;*******************************************************************************   
EXTERN_INITIAL:
;PORT CONFIG
    BANKSEL LATA
    CLRF    LATA
    BANKSEL PORTA
    BSF	    PORTA, ADC_TRIS
    BANKSEL ANSELA
    BSF	    ANSELA, ADC_ANSEL

;ADC CONFIG
    BANKSEL ADCON1
    MOVLF   ADCON1, b'10000000'		; right justified, Fosc/2, VDD ref
    MOVLF   ADCON0, b'00001100'		; set output channel to AN3
    
;ADC INTERRUPT CONFIG
    BANKSEL PIE1
    BSF	    PIE1, ADIE			; enable ADC interrupt
    
;REGISTER CONFIG
    BANKSEL MIN_WAV
    INIT16  MIN_WAV, 0x1FF
    BANKSEL MAX_WAV
    INIT16  MAX_WAV, 0x1FF
    CLR16   DELTA_T
    INIT16  TGRH, 0x1FF
    ADDI16  TGRH, TRIGGER_OFF
    INIT16  TGRL, 0x1FF
    SUBI16  TGRL, TRIGGER_OFF
    
    
;START ADC CONVERSION
    BANKSEL ADCON0
    BSF	    ADCON0, 0			; enable ADC
    ACQ_DELAY				; acquisition delay
    BSF	    ADCON0, ADGO		; start conversion
    
    RETURN
    
 
;*******************************************************************************
;			    EXTERN_INTERRUPT_SERV
;*******************************************************************************
EXTERN_INTERRUPT_SERV:
    ;TODO: determine analog characteristics, then start new adc conversion, clear flags
;    BANKSEL ADRESH
;    CPYFF   ADRESH, WDATA		; copy high adc result to high wdata
;    BANKSEL ADRESL
;    CPYFF   ADRESL, WDATA+1		; copy low adc result to high wdata
    
    ; !!!! WITHIN_TRIGGER unit tests !!!!
;    BANKSEL T3CON
;    BSF	    T3CON, TMR3ON
    BANKSEL WDATA
;    INIT16  WDATA, 0x202
;    INIT16  WDATA, 0x1FC	; 0x1FF +- 3	    |	yes
;    INIT16  WDATA, 0x22E    
;    INIT16  WDATA, 0x1D0	; 0x1FF +- 2F	    |	yes
;    INIT16  WDATA, 0x2FE
;    INIT16  WDATA, 0x1B0	; 0x1FF +- 4F	    |	no
;    INIT16  WDATA, 0x3FF	; 0x3FF		    |	no
    INIT16  WDATA, 0x000	; 0x000		    |	no
;    INIT16  WDATA, 0x1FF	; 0x1FF		    |	yes
   
;TEST FOR NEW WAVE TROUGH
    BANKSEL MIN_WAV
    BCCZ				; clear Z and C  flags
    CMP16   WDATA, MIN_WAV
    BTFSS   STATUS, C			; test if WDATA < MIN_WAV, skip if isn't
    GOTO    SET_TROUGH
    GOTO    END_TEST1
SET_TROUGH:
    MOV16   WDATA, MIN_WAV		; set new MIN_WAV to new WDATA
END_TEST1:
    
;TEST FOR NEW WAVE PEAK
    BANKSEL MAX_WAV
    BCCZ				; clear Z and C  flags
    CMP16   MAX_WAV, WDATA
    BTFSS   STATUS, C			; test if WDATA > MAX_WAV, skip if isn't
    GOTO    SET_PEAK
    GOTO    END_TEST2
SET_PEAK:
    MOV16   WDATA, MAX_WAV		; set new MAX_WAV to new WDATA
END_TEST2:
     
;TEST IF WITHIN TRIGGER WINDOW
    BANKSEL T3CON
    BCCZ				; clear Z and C  flags
    BTFSS   T3CON, TMR3ON		; test whether there has already been a previous trigger
    GOTO    FIRST_TRGR
    GOTO    SECOND_TRGR
FIRST_TRGR:				; if first trigger, start timer3 to measure cycles between triggers
    WITHIN_TRIGGER  WDATA		; C will be set if within trigger window
    BANKSEL T3CON
    BTFSC   STATUS, C
    BSF	    T3CON, TMR3ON		; start timer3 if within trigger window
    GOTO    END_TRGR_TEST		; end trigger window test
SECOND_TRGR:
    WITHIN_TRIGGER  WDATA			; C will be set if within trigger window
    BANKSEL T3CON
    BTFSS   STATUS, C			; end test if not within window
    GOTO    END_TRGR_TEST		; end trigger window test
    BCF	    T3CON, TMR3ON		; turn off timer3
    CPYFF   TMR3H, DELTA_T		; copy timer3 data to DELAT_T
    CPYFF   TMR3L, DELTA_T+1
    CLRF    TMR3L			; clear timer3
    CLRF    TMR3H   
END_TRGR_TEST:
    
;CLEANUP
    BANKSEL PIR1
    BCF	    PIR1, ADIF			; clear ADC interrupt flag
    
    RETURN
    
    
    

    
;*******************************************************************************
;				 DO_RENDER
;*******************************************************************************
DO_RENDER:
    ;TODO: determine color based on analog characteristics
    
    RETURN
    

    
    
    
    
    
    
    
    END