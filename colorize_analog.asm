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
#include UtilRoutines.inc
    
    GLOBAL  DO_RENDER
    GLOBAL  EXTERN_INTERRUPT_SERV
    GLOBAL  EXTERN_INITIAL
    
    EXTERN  WRGB
    EXTERN  RENDER_STATUS
  
;*******************************************************************************
;			      MACRO DEFINITIONS
;*******************************************************************************
ACQ_DELAY   MACRO
   LOCAL    ACQ
   MOVLW    0x0E
ACQ:
    DECFSZ  WREG, W
    GOTO    ACQ
   ENDM
 
WITHIN_WINDOW	MACRO	D	    ; sets C flag of STATUS register
	LOCAL	LBNOTMET
	LOCAL	CHECKUB
	LOCAL	ENDCHECK
	CLRSTAT			    ; clear Z and C flags
	CMP16	TGRL, D		    ; test if above lower trigger - C will be clear
	BTFSC	STATUS, C
	 GOTO	LBNOTMET
	GOTO	CHECKUB
LBNOTMET:
	BCF	STATUS, C
	GOTO	ENDCHECK
CHECKUB:
	CMP16	TGRH, D		    ; will set c if below TGRH
ENDCHECK:
	ENDM
   
;*******************************************************************************
;			    VARIABLE DEFINITIONS
;*******************************************************************************
    #DEFINE ADC_CH	AN3	    ; RA4
    #DEFINE ADC_TRIS	TRISA4
    #DEFINE ADC_ANSEL	ANSA4
    #DEFINE TRIGGER_OFF	0x3F	    ; 10bit resolution  [0V, 5V] corresponds to [0x000, 0x3FF]
				    ; TRIGGER_OFF = 0.5V -> 5V / 10 -> 0x3FF / 10
    #define MIN_FOUND	0
    #define MAX_FOUND	1
    #define POS_SLOPE	2
    #define NEG_SLOPE	3
    #define ALLOW_TRGR2	4  
    #define SAMPL_DONE	5
    #define AMPL_MASK	b'00000011'
    #define SLOPE_MASK	b'00001100'
    
    #define NUM_SAMPLES	1
    
    UDATA   0x20
;TEMP REGISTERS
TEMP8	RES 1
TEMP16	RES 2
    
    
;DATA AND STATUS REGISTERS
WDATA	RES 2		    ; copied data from ADC read
PDATA	RES 2		    ; last read 
SIGNAL	RES 1		    ; bit 0: MIN_WAV found
			    ; bit 1: MAX_WAVE found
			    ; bit 2: POS_SLOPE
			    ; bit 3: NEG_SLOPE
			    ; bit 4: allow trigger 2
			    ; bit 5: SAMPLING_DONE
SAMPLE_COUNT	RES 1
    
;AMPLITUDE REGISTERS
AMPLITUDE   RES 2	    ; calculated amplitude 
MIN_WAV	    RES 2	    ; wave trough
MAX_WAV	    RES 2	    ; wave peak
	
;FREQUENCY REGISTERS
DELTA_T	RES 2				    ; change in timer3 ticks from 2 tiggered plots
TGRH	RES 2;EQU 0x1FF + TRIGGER_OFF	    ; signal coming in biased to 2.5V w/ range [0V, 5V] 
TGRL	RES 2;EQU 0x1FF - TRIGGER_OFF	    ; 2.5V corresponds to 0x3FF / 2 = 0x1FF
	
    ; red colorization parameters
RS1 RES 1		    ; red slope - can be constant or function of frequency (ADC result)
RS2 RES	1
R1  RES	2		    ; red point 1
R2  RES 2		    ; red point 2
R3  RES 2		    ; red point 3
  
    ; green colorization parameters
GS1 RES 1		    ; green slope - can be constant or function of frequency (ADC result)
GS2 RES 1
G1  RES	2		    ; green point 1
G2  RES 2		    ; green point 2
G3  RES 2		    ; green point 3
G4  RES 2		    ; green point 4
  
    ; blue colorization parameters
BS1 RES 1		    ; blue slope - can be constant or function of frequency (ADC result)
B1  RES	2		    ; blue point 1
B2  RES 2		    ; blue point 2
  
COLORIZOR   CODE
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
    BANKSEL SAMPLE_COUNT
    MOVLF   SAMPLE_COUNT, NUM_SAMPLES
    
  
; PIECEWISE PARAMETERS - SEE EXCEL
    ;RED
    BANKSEL RS1
    MOVLF   RS1, 5
    MOVLF   RS2, 6
    INIT16  R1, 8192
    INIT16  R2, 16384
    INIT16  R3, 57344
    
    ;GREEN
    BANKSEL GS1
    MOVLF   GS1, 5
    MOVLF   GS2, 5
    INIT16  G1, 8192
    INIT16  G2, 16384
    INIT16  G3, 24576
    INIT16  G4, 32768
    
    ;BLUE 
    BANKSEL BS1
    MOVLF   BS1, 5
    INIT16  B1, 24576
    INIT16  B2, 32768
     
    
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
    BANKSEL ADRESH
    CPYFF   ADRESH, WDATA		; copy high adc result to high wdata
    BANKSEL ADRESL
    CPYFF   ADRESL, WDATA+1		; copy low adc result to high wdata
    
    ; !!!! WITHIN_TRIGGER unit tests !!!!
;    BANKSEL T3CON
;    BSF	    T3CON, TMR3ON
;    BANKSEL WDATA
;    INIT16  WDATA, 0x202
;    INIT16  WDATA, 0x1FC	; 0x1FF +- 3	    |	yes
;    INIT16  WDATA, 0x22E    
;    INIT16  WDATA, 0x1D0	; 0x1FF +- 2F	    |	yes
;    INIT16  WDATA, 0x2FE
;    INIT16  WDATA, 0x1B0	; 0x1FF +- 4F	    |	no
;    INIT16  WDATA, 0x3FF	; 0x3FF		    |	no
;    INIT16  WDATA, 0x000	; 0x000		    |	no
;    INIT16  WDATA, 0x1FF	; 0x1FF		    |	yes
   
;TEST FOR NEW WAVE TROUGH
    BANKSEL MIN_WAV
    CLRSTAT				; clear Z and C  flags
    CMP16   WDATA, MIN_WAV
    BTFSS   STATUS, C			; test if WDATA < MIN_WAV, skip if isn't
    GOTO    SET_TROUGH
    GOTO    END_TEST1
SET_TROUGH:
    MOV16   WDATA, MIN_WAV		; set new MIN_WAV to new WDATA
    BANKSEL SIGNAL
    BSF	    SIGNAL, MIN_FOUND
END_TEST1:
    
;TEST FOR NEW WAVE PEAK
    BANKSEL MAX_WAV
    CLRSTAT				; clear Z and C  flags
    CMP16   MAX_WAV, WDATA
    BTFSS   STATUS, C			; test if WDATA > MAX_WAV, skip if isn't
    GOTO    SET_PEAK
    GOTO    END_TEST2
SET_PEAK:
    MOV16   WDATA, MAX_WAV		; set new MAX_WAV to new WDATA
    BANKSEL SIGNAL
    BSF	    SIGNAL, MAX_FOUND
END_TEST2:
     

SLOPE_TEST:
;TEST FOR POSITIVE OR NEGATIVE SLOPES
    BCF	    STATUS, C
    CMP16   WDATA, PDATA		; compare WDATA and PDATA to see the rate of change 
    BTFSS   STATUS, C			; 
     BSF    SIGNAL, NEG_SLOPE
    BTFSC   SIGNAL, C
     BSF    SIGNAL, POS_SLOPE
    MOVF    SIGNAL, W
    BCF	    STATUS, Z
    ANDLW   SLOPE_MASK
    SUBLW   SLOPE_MASK
    BTFSS   STATUS, Z
     GOTO   TRIGGER_WINDOW_TEST
    BSF	    SIGNAL, ALLOW_TRGR2
     
TRIGGER_WINDOW_TEST: 
;TEST IF WITHIN TRIGGER WINDOW
    BANKSEL T3CON
    CLRSTAT				; clear Z and C  flags
    BTFSS   T3CON, TMR3ON		; test whether there has already been a previous trigger
    GOTO    FIRST_TRGR
    GOTO    SECOND_TRGR
FIRST_TRGR:				; if first trigger, start timer3 to measure cycles between triggers
    BANKSEL WDATA
    WITHIN_WINDOW  WDATA		; C will be set if within trigger window
    BANKSEL T3CON
    BTFSC   STATUS, C
    BSF	    T3CON, TMR3ON		; start timer3 if within trigger window
    GOTO    END_TRGR_TEST		; end trigger window test
SECOND_TRGR:
    BANKSEL WDATA
    WITHIN_WINDOW  WDATA		; C will be set if within trigger window
    BTFSS   SIGNAL, ALLOW_TRGR2
     GOTO   END_TRGR_TEST
    BANKSEL T3CON
    BTFSS   STATUS, C			; end test if not within window
    GOTO    END_TRGR_TEST		; end trigger window test
    BCF	    T3CON, TMR3ON		; turn off timer3
    CPYFF   TMR3H, DELTA_T+1		; copy timer3 data to DELAT_T
    CPYFF   TMR3L, DELTA_T
    CLRF    TMR3L			; clear timer3
    CLRF    TMR3H   
    BANKSEL SIGNAL
    BCF	    SIGNAL, POS_SLOPE		; clear SIGNAL rate of change status flags
    BCF	    SIGNAL, NEG_SLOPE
    BCF	    SIGNAL, ALLOW_TRGR2
END_TRGR_TEST:
    
;CLEANUP
    BANKSEL PIR1
    BCF	    PIR1, ADIF			; clear ADC interrupt flag
    MOV16   WDATA, PDATA		; copy data to past data register 
    BCF	    STATUS, Z
    BANKSEL SAMPLE_COUNT
    DECF    SAMPLE_COUNT, F
    BTFSC   STATUS, Z
     BSF    SIGNAL, SAMPL_DONE
    
;START NEXT ADC CONVERSION
;    BANKSEL ADCON0
;    BSF	    ADCON0, 0			; enable ADC
;    ACQ_DELAY				; acquisition delay
;    BSF	    ADCON0, ADGO		; start conversion
    
    RETURN
    
    
    

    
;*******************************************************************************
;				 DO_RENDER
;*******************************************************************************
DO_RENDER:
;WAIT FOR SAMPLING TO COMPLETE
;    BANKSEL SIGNAL
;    BTFSS   SIGNAL, SAMPL_DONE
;     GOTO   $-1
;    MOVLF   SAMPLE_COUNT, NUM_SAMPLES 
;    
    
;SET COLOR
    BANKSEL DELTA_T
    INIT16  DELTA_T, 12288
    
    PAGESEL SET_WRGB
    CALL    SET_WRGB
    
;    CALC_AMPLITUDE:
;;TEST WHETHER A MAX AND MIN HAS BEEN FOUND 
;    BCF	    STATUS, Z			; clear Z flag of STATUS register
;    MOVF    SIGNAL, W			; move SIGNAL status register to WREG
;    ANDLW   AMPL_MASK			; mask SIGNAL for data about the wave's amplitude
;    SUBLW   AMPL_MASK			; if a max and min has been found, both bits will be set and will be 
;    BTFSS   STATUS, Z			; equal to the mask and will cause the Z flag to be set upon subtraction
;     GOTO    TRIGGER_WINDOW_TEST	; min and max weren't found
;    MOV16   MAX_WAV, AMPLITUDE
;    SUB16   AMPLITUDE, MIN_WAV		; MAX_WAV - MIN_WAV
;    RSF16   AMPLITUDE, 1		; divide by 2
;    BANKSEL SIGNAL
;    MOVLF   SIGNAL, b'00000100'		; clear MIN_FOUND and MAX_FOUND 
    
    
    
    RETURN
    

    
    
SET_WRGB:

; GREEN PIECEWISE FUNCTION    
;   | 0x00		, f <= G1
;   | GS1(f-G1)		, G1 < f <= G2
;   | 0xFF		, G2 < f <= G3
;   | 0xFF - GS1(f-G3)	, G3 < f <= G4
;   | 0x00		, f > G4
;
SET_GREEN:
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, G1			; check for first range in piecewise
    BTFSS   STATUS, C			
    GOTO    G_1				; within first range
    GOTO    G_12			; MIGHT be in the next range
G_1:	; first range in piecewise
    BANKSEL WRGB
    MOVLF   WRGB, 0x00
    GOTO    SET_RED
    
G_12:   ; second range in piecewise
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, G2
    BTFSC   STATUS, C	
     GOTO    G_23			; might be in the next range 
    
    MOV16   DELTA_T, TEMP16		; in this range
    SUB16   TEMP16, G1			; (f - G1)
    RSF16   TEMP16, GS1			; (f - G1) / (1/m >> GS)
    BANKSEL WRGB
    CPYFF   TEMP16, WRGB		; WRGB in GRB format
    GOTO    SET_RED
    
G_23:	; third range in piecewise
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, G3
    BTFSC   STATUS, C			; might be in next range 
     GOTO    G_34
    
    BANKSEL WRGB			; in this range 
    MOVLF   WRGB, 0xFF
    GOTO    SET_RED
    
G_34:	; fourth range in piecewise
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, G2
    BTFSC   STATUS, C	
     GOTO    G_4			; it is in the fifth range
    
    MOV16   DELTA_T, TEMP16		; in this range
    SUB16   TEMP16, G1			; (f - G1)
    RSF16   TEMP16, GS2			; (f - G1) / (1/m >> GS)
    MOVLF   TEMP8, 0xFF
    MOVFW   TEMP16
    SUBWF   TEMP8, F
    BANKSEL WRGB
    CPYFF   TEMP8, WRGB			; WRGB in GRB format
    GOTO    SET_RED
    
G_4:	; fifth range in piecewise
    BANKSEL WRGB
    MOVLF   WRGB, 0x00
    
    
    
; RED PIECEWISE FUNCTION    
;   | 0xFF		, f <= R1
;   | 0xFF - RS2(f-GR), R1 < f <= R2
;   | 0x00		, R2 < f <= R3
;   | RS1(f-R1)		, f > R3
;    
SET_RED:
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, R1
    BTFSS   STATUS, C			; test if WDATA <= R1
    GOTO    R_1
    GOTO    R_12
R_1:	; WDATA <= R1
    BANKSEL WRGB
    MOVLF   WRGB+1, 0xFF
    GOTO    SET_BLUE
    
R_12:   ; R1 < WDATA <= R2 
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, R2
    BTFSC   STATUS, C	
     GOTO    R_23			; go to R_23 if WDATA not within range of R_12
    
    MOV16   DELTA_T, TEMP16		; (f - R1)
    SUB16   TEMP16, R1
    RSF16   TEMP16, RS1			; (f - R1) / (1/m >> RS)
    MOVLF   TEMP8, 0xFF
    MOVFW   TEMP16
    SUBWF   TEMP8, F
    BANKSEL WRGB
    CPYFF   TEMP8, WRGB+1		; WRGB in GRB format
    GOTO    SET_BLUE
    
R_23:	; R2 < WDATA <= R3 
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, R3
    BTFSC   STATUS, C	
     GOTO    R_3
    
    BANKSEL WRGB
    MOVLF   WRGB+1, 0x00
    GOTO    SET_BLUE
    
R_3:	; WDATA > R3
    BCF	    STATUS, C
    BANKSEL DELTA_T
    MOV16   DELTA_T, TEMP16		; (f - R1)
    SUB16   TEMP16, R3
    RSF16   TEMP16, RS2			; (f - R1) / (1/m >> RS)
    BANKSEL WRGB
    CPYFF   TEMP16, WRGB+1		; WRGB in GRB format
  
    
    
; BLUE PIECEWISE FUNCTION    
;   | 0x00		, f <= B1
;   | GS1(f-G1)		, B1 < f <= B2
;   | 0xFF		, f > B2
SET_BLUE:    
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, B1			; check for first range in piecewise
    BTFSS   STATUS, C			
    GOTO    B_1				; within first range
    GOTO    B_12			; MIGHT be in the next range
B_1:	; first range in piecewise
    BANKSEL WRGB
    MOVLF   WRGB, 0x00
    RETURN
    
B_12:   ; second range in piecewise
    BCF	    STATUS, C
    BANKSEL DELTA_T
    CMP16   DELTA_T, B2
    BTFSC   STATUS, C	
     GOTO    B_23			; might be in the next range 
    
    MOV16   DELTA_T, TEMP16		; in this range
    SUB16   TEMP16, B1			; (f - G1)
    RSF16   TEMP16, BS1			; (f - G1) / (1/m >> GS)
    BANKSEL WRGB
    CPYFF   TEMP16, WRGB		; WRGB in GRB format
    RETURN
    
B_23:	; third range in piecewise
    BCF	    STATUS, C
    BANKSEL WRGB			 
    MOVLF   WRGB, 0xFF
    RETURN

    
    END
    