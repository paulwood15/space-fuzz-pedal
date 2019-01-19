; list	R=DEC
;;*******************************************************************************
;;
;; Program: WS2813
;; Author: Paul Wood
;; Date Created: 06/30/2018 5:40PM
;; Purpose: To display patterns on WS2813 based RGB LED strip
;;
;;*******************************************************************************
;;
;; Program Hierarchy:
;;
;;
;;*******************************************************************************
;;				  EXTERNALS
;;*******************************************************************************
;#include p16f1615.inc
;#include WS2813.inc
;#include UtilMacros.inc
;#include UtilRoutines.inc
;    
;    GLOBAL  DO_RENDER
;    GLOBAL  EXTERN_INTERRUPT_SERV
;    GLOBAL  EXTERN_INITIAL
;    
;    EXTERN  WRGB
;    EXTERN  RENDER_STATUS
;  
;;*******************************************************************************
;;			      MACRO DEFINITIONS
;;*******************************************************************************
;ACQ_DELAY   MACRO
;   LOCAL    ACQ
;   MOVLW    0x0E
;ACQ:
;    DECFSZ  WREG, W
;    GOTO    ACQ
;   ENDM
;; MSGEQ7_RESET_PULSE MACRO
;    
;   
;   
;WITHIN_WINDOW	MACRO	D	    ; sets C flag of STATUS register
;	LOCAL	LBNOTMET
;	LOCAL	CHECKUB
;	LOCAL	ENDCHECK
;	CLRSTAT			    ; clear Z and C flags
;	CMP16	TGRL, D		    ; test if above lower trigger - C will be clear
;	BTFSC	STATUS, C
;	 GOTO	LBNOTMET
;	GOTO	CHECKUB
;LBNOTMET:
;	BCF	STATUS, C
;	GOTO	ENDCHECK
;CHECKUB:
;	CMP16	TGRH, D		    ; will set c if below TGRH
;ENDCHECK:
;	ENDM
;   
;;*******************************************************************************
;;			    VARIABLE DEFINITIONS
;;*******************************************************************************
;    #DEFINE ADC_TRIS	TRISA2
;    #DEFINE ADC_ANSEL	ANSA2
;    
;    
;    UDATA   0x20
;;TEMP REGISTERS
;TEMP8	RES 1
;TEMP16	RES 2
;    
;    
;;DATA AND STATUS REGISTERS
;WDATA	RES 2		    ; copied data from ADC read
;PDATA	RES 2		    ; last read 
;SIGNAL	RES 1		    ; bit 0: MIN_WAV found
;			    ; bit 1: MAX_WAVE found
;			    ; bit 2: POS_SLOPE
;			    ; bit 3: NEG_SLOPE
;			    ; bit 4: allow trigger 2
;			    ; bit 5: SAMPLING_DONE
;	
;    ; red colorization parameters
;RS1 RES 1		    ; red slope - can be constant or function of frequency (ADC result)
;RS2 RES	1
;R1  RES	2		    ; red point 1
;R2  RES 2		    ; red point 2
;R3  RES 2		    ; red point 3
;  
;    ; green colorization parameters
;GS1 RES 1		    ; green slope - can be constant or function of frequency (ADC result)
;GS2 RES 1
;G1  RES	2		    ; green point 1
;G2  RES 2		    ; green point 2
;G3  RES 2		    ; green point 3
;G4  RES 2		    ; green point 4
;  
;    ; blue colorization parameters
;BS1 RES 1		    ; blue slope - can be constant or function of frequency (ADC result)
;B1  RES	2		    ; blue point 1
;B2  RES 2		    ; blue point 2
;  
;COLORIZOR   CODE
;;*******************************************************************************
;;				EXTERN_INITIAL
;;*******************************************************************************   
;EXTERN_INITIAL:
;;PORT CONFIG
;    BANKSEL LATA
;    CLRF    LATA
;    BANKSEL PORTA
;    BSF	    PORTA, ADC_TRIS
;    BANKSEL ANSELA
;    BSF	    ANSELA, ADC_ANSEL
;
;;ADC CONFIG
;    BANKSEL ADCON1
;    MOVLF   ADCON1, b'11000000'		; right justified, Fosc/2, VDD ref
;    MOVLF   ADCON0, b'00001001'		; enable and set output channel to AN2
;    
;; PIECEWISE PARAMETERS - SEE EXCEL
;    ;RED
;    BANKSEL RS1
;    MOVLF   RS1, 5
;    MOVLF   RS2, 6
;    INIT16  R1, 8192
;    INIT16  R2, 16384
;    INIT16  R3, 57344
;    
;    ;GREEN
;    BANKSEL GS1
;    MOVLF   GS1, 5
;    MOVLF   GS2, 5
;    INIT16  G1, 8192
;    INIT16  G2, 16384
;    INIT16  G3, 24576
;    INIT16  G4, 32768
;    
;    ;BLUE 
;    BANKSEL BS1
;    MOVLF   BS1, 5
;    INIT16  B1, 24576
;    INIT16  B2, 32768
;     
;    
;    RETURN
;    
; 
;;*******************************************************************************
;;			    EXTERN_INTERRUPT_SERV
;;*******************************************************************************
;EXTERN_INTERRUPT_SERV:
;    
;    
;    RETURN
;    
;    
;    
;
;    
;;*******************************************************************************
;;				 DO_RENDER
;;*******************************************************************************
;DO_RENDER:
;    BANKSEL WRGB		    
;    MOVLF   WRGB, 0xFF		    ; green 
;    MOVLF   WRGB+1, 0x00	    ; red 
;    MOVLF   WRGB+2, 0x00	    ; blue 
;    
;    RETURN
;
;    
;    
;;SET_WRGB:
;;
;;; GREEN PIECEWISE FUNCTION    
;;;   | 0x00		, f <= G1
;;;   | GS1(f-G1)		, G1 < f <= G2
;;;   | 0xFF		, G2 < f <= G3
;;;   | 0xFF - GS1(f-G3)	, G3 < f <= G4
;;;   | 0x00		, f > G4
;;;
;;SET_GREEN:
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, G1			; check for first range in piecewise
;;    BTFSS   STATUS, C			
;;    GOTO    G_1				; within first range
;;    GOTO    G_12			; MIGHT be in the next range
;;G_1:	; first range in piecewise
;;    BANKSEL WRGB
;;    MOVLF   WRGB, 0x00
;;    GOTO    SET_RED
;;    
;;G_12:   ; second range in piecewise
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, G2
;;    BTFSC   STATUS, C	
;;     GOTO    G_23			; might be in the next range 
;;    
;;    MOV16   DELTA_T, TEMP16		; in this range
;;    SUB16   TEMP16, G1			; (f - G1)
;;    RSF16   TEMP16, GS1			; (f - G1) / (1/m >> GS)
;;    BANKSEL WRGB
;;    CPYFF   TEMP16, WRGB		; WRGB in GRB format
;;    GOTO    SET_RED
;;    
;;G_23:	; third range in piecewise
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, G3
;;    BTFSC   STATUS, C			; might be in next range 
;;     GOTO    G_34
;;    
;;    BANKSEL WRGB			; in this range 
;;    MOVLF   WRGB, 0xFF
;;    GOTO    SET_RED
;;    
;;G_34:	; fourth range in piecewise
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, G2
;;    BTFSC   STATUS, C	
;;     GOTO    G_4			; it is in the fifth range
;;    
;;    MOV16   DELTA_T, TEMP16		; in this range
;;    SUB16   TEMP16, G1			; (f - G1)
;;    RSF16   TEMP16, GS2			; (f - G1) / (1/m >> GS)
;;    MOVLF   TEMP8, 0xFF
;;    MOVFW   TEMP16
;;    SUBWF   TEMP8, F
;;    BANKSEL WRGB
;;    CPYFF   TEMP8, WRGB			; WRGB in GRB format
;;    GOTO    SET_RED
;;    
;;G_4:	; fifth range in piecewise
;;    BANKSEL WRGB
;;    MOVLF   WRGB, 0x00
;;    
;;    
;;    
;;; RED PIECEWISE FUNCTION    
;;;   | 0xFF		, f <= R1
;;;   | 0xFF - RS2(f-GR), R1 < f <= R2
;;;   | 0x00		, R2 < f <= R3
;;;   | RS1(f-R1)		, f > R3
;;;    
;;SET_RED:
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, R1
;;    BTFSS   STATUS, C			; test if WDATA <= R1
;;    GOTO    R_1
;;    GOTO    R_12
;;R_1:	; WDATA <= R1
;;    BANKSEL WRGB
;;    MOVLF   WRGB+1, 0xFF
;;    GOTO    SET_BLUE
;;    
;;R_12:   ; R1 < WDATA <= R2 
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, R2
;;    BTFSC   STATUS, C	
;;     GOTO    R_23			; go to R_23 if WDATA not within range of R_12
;;    
;;    MOV16   DELTA_T, TEMP16		; (f - R1)
;;    SUB16   TEMP16, R1
;;    RSF16   TEMP16, RS1			; (f - R1) / (1/m >> RS)
;;    MOVLF   TEMP8, 0xFF
;;    MOVFW   TEMP16
;;    SUBWF   TEMP8, F
;;    BANKSEL WRGB
;;    CPYFF   TEMP8, WRGB+1		; WRGB in GRB format
;;    GOTO    SET_BLUE
;;    
;;R_23:	; R2 < WDATA <= R3 
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, R3
;;    BTFSC   STATUS, C	
;;     GOTO    R_3
;;    
;;    BANKSEL WRGB
;;    MOVLF   WRGB+1, 0x00
;;    GOTO    SET_BLUE
;;    
;;R_3:	; WDATA > R3
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    MOV16   DELTA_T, TEMP16		; (f - R1)
;;    SUB16   TEMP16, R3
;;    RSF16   TEMP16, RS2			; (f - R1) / (1/m >> RS)
;;    BANKSEL WRGB
;;    CPYFF   TEMP16, WRGB+1		; WRGB in GRB format
;;  
;;    
;;    
;;; BLUE PIECEWISE FUNCTION    
;;;   | 0x00		, f <= B1
;;;   | GS1(f-G1)		, B1 < f <= B2
;;;   | 0xFF		, f > B2
;;SET_BLUE:    
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, B1			; check for first range in piecewise
;;    BTFSS   STATUS, C			
;;    GOTO    B_1				; within first range
;;    GOTO    B_12			; MIGHT be in the next range
;;B_1:	; first range in piecewise
;;    BANKSEL WRGB
;;    MOVLF   WRGB+2, 0x00
;;    RETURN
;;    
;;B_12:   ; second range in piecewise
;;    BCF	    STATUS, C
;;    BANKSEL DELTA_T
;;    CMP16   DELTA_T, B2
;;    BTFSC   STATUS, C	
;;     GOTO    B_23			; might be in the next range 
;;    
;;    MOV16   DELTA_T, TEMP16		; in this range
;;    SUB16   TEMP16, B1			; (f - G1)
;;    RSF16   TEMP16, BS1			; (f - G1) / (1/m >> GS)
;;    BANKSEL WRGB
;;    CPYFF   TEMP16, WRGB+2		; WRGB in GRB format
;;    RETURN
;;    
;;B_23:	; third range in piecewise
;;    BCF	    STATUS, C
;;    BANKSEL WRGB			 
;;    MOVLF   WRGB+2, 0xFF
;;    RETURN
;
    
    END
    