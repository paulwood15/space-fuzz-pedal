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
;			       CONFIGURATION BITS
;*******************************************************************************
 list	R=DEC
#include p16f1615.inc

; CONFIG1
; __config 0xFFFC
 __CONFIG _CONFIG1, _FOSC_INTOSC & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_ON & _ZCD_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON
; CONFIG3
; __config 0xFF9F
 __CONFIG _CONFIG3, _WDTCPS_WDTCPS1F & _WDTE_OFF & _WDTCWS_WDTCWSSW & _WDTCCS_SWC

 

;*******************************************************************************
;			    VARIABLE DEFINITIONS
;*******************************************************************************
#DEFINE WS2813_PIN	LATC4	    ; MUST use PORTC
#DEFINE	NUM_LEDS	60	    ; number of LEDs in strip
#DEFINE ADC_ANSEL	ANSA2
#DEFINE RED_SPECTRUM_CH		1
#DEFINE GREEN_SPECTRUM_CH	3
#DEFINE BLUE_SPECTRUM_CH	5
#DEFINE MSGEQ7_READ_PIN		TRISA2
#DEFINE MSGEQ7_ANSEL_PIN	ANSA2
#DEFINE MSGEQ7_WPU_PIN		WPUA2
#DEFINE MSGEQ7_STROBE_PIN	LATC3
#DEFINE	MSGEQ7_RESET_PIN	LATC5

VARS    UDATA   0x120
BCOUNT		RES 1		; Bit count- for use for when 
				; displaying a color in ws2813_write
SHIFTNUM	RES 2
FRAMECOUNT	RES 1
WRITE_COUNT	RES 1		; reserve 1byte for write counter
WS2813_RESET	RES 2		; to save operations, this works as two, nested   
WS2813_RESET_COPY   RES 2	; for loops. First byte is for outer loop, 
				; second byte is for inner loop; = 256^2
WCOLOR	RES 3			; reserve 24bits for RGB color (IN G,R,B FORMAT)	
WDATA	RES 2
   
	
	cblock
	d0
	endc
	
;*******************************************************************************
;				 VECTORS
;******************************************************************************* 
	
RES_VECT  CODE    0x0000            ; processor reset vector
    PAGESEL START
    GOTO    START                   ; go to beginning of program     

;*******************************************************************************
;			      MACRO DEFINITIONS
;*******************************************************************************
MOVLF	MACRO	DEST, LIT
	BANKSEL	DEST
	MOVLW	LIT
	MOVWF	DEST
	ENDM
	
MOVLF16	MACRO   DEST,LIT
	BANKSEL	LIT
	MOVLW	LIT & B'0000000011111111'
	BANKSEL	DEST
	MOVWF	DEST
	BANKSEL	LIT
	MOVLW	LIT >> 8
	BANKSEL	DEST
	MOVWF	DEST+1
	ENDM
	
BCZ	MACRO	 
	BCF	STATUS, Z
	ENDM
	
CPYFF	MACRO	FROM,TO
	MOVF	FROM, W
	MOVWF	TO
	ENDM
	
BITHIGH	MACRO	
	BSF	LATC, WS2813_PIN
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	BCF	LATC, WS2813_PIN
	ENDM
	
BITLOW	MACRO
	BSF	LATC, WS2813_PIN
	NOP
	NOP
	BCF	LATC, WS2813_PIN
	NOP
	NOP
	NOP
	NOP
	NOP
	ENDM
	
READ_ADC    MACRO
	BANKSEL	ADCON0
	BSF	ADCON0, ADGO
	BTFSC	ADCON0, ADGO
	 GOTO	$-1
	BANKSEL	ADRESH
	MOVF	ADRESH, W
	BANKSEL	WDATA
	MOVWF	WDATA+1
	BANKSEL	ADRESL
	MOVF	ADRESL
	BANKSEL	WDATA
	MOVWF	WDATA
	ENDM
	
	
MSGEQ7_RESET	MACRO
	BANKSEL	LATC
	BSF	LATC, MSGEQ7_RESET_PIN
	BCF	LATC, MSGEQ7_RESET_PIN
	ENDM
	
TMR1_OFFSET MACRO   LIT
	BANKSEL	TMR1H
	MOVLF	TMR1H, high LIT
	MOVLF	TMR1L, low LIT
	ENDM
	
MSGEQ7_STROBE_LOW MACRO
	BANKSEL	LATC
	BCF	LATC, MSGEQ7_STROBE_PIN
	
	TMR1_DELAY 65104
	ENDM
	
MSGEQ7_STROBE_HIGH  MACRO
	BANKSEL	LATC
	BSF	LATC, MSGEQ7_STROBE_PIN
	
	TMR1_DELAY 655408
	
	BANKSEL	LATC
	ENDM

MSGEQ7_STROBE	MACRO
	MSGEQ7_STROBE_HIGH
	MSGEQ7_STROBE_LOW
	ENDM
	
	
READ_SETTLE MACRO
	TMR1_DELAY 65232
	ENDM
	
TMR1_DELAY  MACRO   LIT
	TMR1_OFFSET LIT
	BANKSEL	T1CON
	BSF	T1CON, TMR1ON
	BANKSEL	PIR1
	BTFSS	PIR1, TMR1IF
	 GOTO $-1
	BANKSEL	T1CON
	BCF	T1CON, TMR1ON
	BANKSEL	PIR1
	BCF	PIR1, TMR1IF
	ENDM
	
	
ACQ_DELAY   MACRO
   LOCAL    ACQ
   MOVLW    0x0E
ACQ
    DECFSZ  WREG, W
    GOTO    ACQ
   ENDM
   
MOV16   MACRO   SRC, DST
        BANKSEL	SRC
	MOVF    SRC,W
	BANKSEL	DST
        MOVWF   DST
	BANKSEL	SRC
        MOVF    SRC+1,W
	BANKSEL	DST
        MOVWF   DST+1
        ENDM
;*******************************************************************************
;			  INTERRUPT SERVICE ROUTINE
;*******************************************************************************
     
; TODO
	
;*******************************************************************************
;			       INITIALIZATION
;*******************************************************************************
MAIN_PROG CODE                      ; let linker place main program
 
INITIAL:
    ;PORT CONFIG
    BANKSEL LATA
    BSF	    LATA, MSGEQ7_READ_PIN
    BANKSEL ANSELA
    BSF	    ANSELA, MSGEQ7_ANSEL_PIN
    BANKSEL WPUA
    BSF	    WPUA, MSGEQ7_WPU_PIN
    
    BANKSEL TRISC
    BCF	    TRISC, WS2813_PIN	    ; set WS2813_PIN as the output pin for serial data
    BCF	    TRISC, MSGEQ7_STROBE_PIN
    BCF	    TRISC, MSGEQ7_RESET_PIN
    MOVLF   SLRCONC, 0X00	    ; allow for maximum slew rate
    BSF	    HIDRVC, HIDC4	    ; enable high current drive for C4
    
    
    
    BANKSEL OSCCON
    MOVLF   OSCCON, B'01110000'	    ; set HS internal clock to 8MHz
    ;CALL    DELAY
    BSF     OSCCON, SPLLEN	    ; Kick in 4X PLL
    
    
    BANKSEL WCOLOR		    ; initalize COLOR variable to solid green
    MOVLF   WCOLOR, 0x00	    ; green = 255
    MOVLF   WCOLOR+1, 0x00	    ; red = 0
    MOVLF   WCOLOR+2, 0x00	    ; blue = 0
    
    MOVLF   WS2813_RESET, 30	    ; Nol * Nil = (Ntot - 7) / 20
    MOVLF   WS2813_RESET+1, 50	    ; Ntot = (Tdelay * Fosc)
    
    MOVLF   FRAMECOUNT, 30
  
    
;ADC CONFIG
    BANKSEL ADCON1
    MOVLF   ADCON1, b'11000000'		; right justified, Fosc/2, VDD ref
    MOVLF   ADCON0, b'00001001'		; enable and set output channel to AN2
    
;TMR1
    BANKSEL T1CON
    MOVLF   T1CON, 0x00
    BANKSEL PIE1
    BSF	    PIE1, TMR1IE
    
    
    
    
    
    RETURN    
	
;*******************************************************************************
;				    MAIN
;*******************************************************************************
START:	    
    CALL    INITIAL		

RENDER_LOOP:
    MSGEQ7_RESET
    
    
    
    BsF	LATC, MSGEQ7_STROBE_PIN
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    
    BCF	LATC, MSGEQ7_STROBE_PIN
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    TMR1_DELAY	0
    
;    
;;RED - FIRST BAND
;    MSGEQ7_STROBE
;    READ_SETTLE
;    READ_ADC
;    MOVLW   2
;    CALL    RSHIFT16
;    CPYFF   WDATA, WCOLOR+1
;    
;;GREEN - THIRD BAND
;    READ_SETTLE
;    MSGEQ7_STROBE
;    MSGEQ7_STROBE
;    READ_ADC
;    MOVLW   2
;    CALL    RSHIFT16
;    CPYFF   WDATA, WCOLOR
;    
;    CALL    WRITE_FRAME
;    CALL    DELAY		    ; finish up frame - add delay to reset LEDs 
;    GOTO    RENDER_LOOP
;    
;    
;;BLUE - FIFTH BAND
;    MSGEQ7_STROBE
;    MSGEQ7_STROBE
;    READ_SETTLE
;    READ_ADC
;    MOVLW   2
;    CALL    RSHIFT16
;    CPYFF   WDATA, WCOLOR+2
;    
;    
;    CALL    WRITE_FRAME
;    CALL    DELAY		    ; finish up frame - add delay to reset LEDs 
;    GOTO    RENDER_LOOP
; 
;WRITE_FRAME:
;    MOVLF   WRITE_COUNT, NUM_LEDS   ; copy NUM_LEDS to WRITE_COUNT
;    DECFSZ  FRAMECOUNT
;    GOTO    WRITE_LED
;    MOVLF   FRAMECOUNT, NUM_LEDS
;    
;WRITE_LED:
;    CALL    WS2813_WRITE	    ; write out LED to strip
;    DECFSZ  WRITE_COUNT, F		    
;    GOTO    WRITE_LED		    ; repeat until all LEDs have been written to
    
    RETURN
    

;*******************************************************************************
;				    DELAY
;*******************************************************************************
DELAY:
    BANKSEL WS2813_RESET
    CPYFF   WS2813_RESET, WS2813_RESET_COPY
    
OL:				    ; outer loop (nested for loops)
    CPYFF   WS2813_RESET+1, WS2813_RESET_COPY+1
    DECFSZ  WS2813_RESET_COPY, F
    GOTO    IL
    GOTO    DONE
IL:				    ; outer loop
    DECFSZ  WS2813_RESET_COPY+1, F
    GOTO    $-1
    GOTO    OL
DONE:
    RETURN
    
    
    

;*******************************************************************************
;				 WS2813_WRITE
;*******************************************************************************
WS2813_WRITE:
    ;
    ;
    ;
    ; GREEN
    BTFSS   WCOLOR, 7
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 6
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 5
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 4
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 3
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 2
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 1
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR, 0
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    ;
    ;
    ;
    ; RED
    BTFSS   WCOLOR+1, 7
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 6
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 5
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 4
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 3
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 2
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 1
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+1, 0
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    ;
    ;
    ;
    ; BLUE
    BTFSS   WCOLOR+2, 7
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 6
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 5
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 4
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 3
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 2
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 1
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BITLOW
    
    BTFSS   WCOLOR+2, 0
    GOTO    $+11
    BITHIGH
    GOTO    $+10
    BSF	LATC, WS2813_PIN
    NOP
    NOP
    BCF	LATC, WS2813_PIN
    NOP
    NOP
    ;NOP
    ;NOP
    ;NOP
    RETURN

    
    
    
    
RSHIFT16:
    LOCAL   RSLOOP
    BCF	    STATUS, C
    BCF	    STATUS, Z
    BANKSEL WREG
    BTFSC   WREG, 0			; check for odd number - will be ignored
     BSF    STATUS, Z

RSLOOP:
    BANKSEL WDATA
    BTFSC   WDATA+1, 0
     BSF    STATUS, C
    LSRF    WDATA
    LSRF    WDATA+1
    BTFSC   STATUS, C
     BSF    WDATA, 7
    BCF	    STATUS, C
    DECFSZ  WREG
     GOTO   RSLOOP
    
    RETURN    
    
    
    
    
    
    END	
    
    
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
;;				   EXTERNALS
;;*******************************************************************************
;#include p16f1615.inc
;#include WS2813.inc
;#include UtilMacros.inc
;    
;    GLOBAL  WRGB
;    GLOBAL  RENDER_CON
;    GLOBAL  RENDER_STATUS
;    
;    EXTERN  DO_RENDER
;    EXTERN  EXTERN_INTERRUPT_SERV
;    EXTERN  EXTERN_INITIAL
;    
;;*******************************************************************************
;;			       CONFIGURATION BITS
;;*******************************************************************************
; list	R=DEC
;
;; CONFIG1
;; __config 0x2FFC
; __CONFIG _CONFIG1, _FOSC_INTOSC & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON
;; CONFIG2
;; __config 0x3FFF
; __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_ON & _ZCD_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON
;; CONFIG3
;; __config 0x3FEF
; __CONFIG _CONFIG3, _WDTCPS_WDTCPSF & _WDTE_ON & _WDTCWS_WDTCWSSW & _WDTCCS_SWC
;
; 
;;*******************************************************************************
;;				 VECTORS
;;******************************************************************************* 
;	
;RES_VECT  CODE    0x0000            ; processor reset vector
;    PAGESEL START
;    GOTO    START		    ; go to beginning of program     
;    
;INTERRUPT_VECT	CODE 0X0004	    ; interrupt service routine vector
;    PAGESEL INTERRUPT_SERV
;    GOTO    INTERRUPT_SERV	    ; serve interrupt
;
;;*******************************************************************************
;;			      MACRO DEFINITIONS
;;*******************************************************************************	
;BITHIGH	MACRO	
;	BSF	LATC, WS2813_LAT
;	NOP
;	NOP
;	NOP
;	NOP
;	NOP
;	NOP
;	NOP
;	BCF	LATC, WS2813_LAT
;	ENDM
;	
;BITLOW	MACRO
;	BSF	LATC, WS2813_LAT
;	NOP
;	NOP
;	BCF	LATC, WS2813_LAT
;	NOP
;	NOP
;	NOP
;	NOP
;	NOP
;	ENDM
;	
;RENDER_CLEANUP	MACRO	
;	BANKSEL T1CON
;	BCF	    T1CON, TMR1ON	    ; turn off T1 counting
;	BANKSEL TMR1L
;	MOVLF   TMR1L, low TMR1_OFFSET	    ; set TMR1 for set FPS 
;	MOVLF   TMR1H, high TMR1_OFFSET	    ; set TMR1 for set FPS 
;	BANKSEL LATC
;	BCF	    LATC, WS2813_LAT	    ; make sure data pin is LOW
;	BANKSEL PIR1
;	BCF	    PIR1,TMR1IF		    ; clear TMR1 interrupt flag
;	ENDM
;	
;	
;;*******************************************************************************
;;			    VARIABLE DEFINITIONS
;;*******************************************************************************
;#define	HIGH_SZ	14
;#define LOW_SZ	10
;	
;	
;FSR_BUFFER_START    EQU	0x2000 + (GPR_SIZE * 3)	; linear addressing != address on memory map	
;						; lin_mem_start + (GPR_size * bank_n)
;						; ex: start in BANK0 -> bank_n = 0, BANK1 -> bank_n = 1
;						
;FSR_WRGB    EQU	0x20A0	; FSR address for WRGB 
;	
;; Register variables
;REGISTERS   UDATA   0x120		
;WRGB	    RES 3		; reserve 24bits for RGB color (IN G,R,B FORMAT)
;LEDCOUNT    RES 1		; copy of bank selection to save context
;FRAMECOUNT  RES 1
;WRITE_COUNT RES 1		; reserve 1byte for write counter
; 
;   
;; RENDER CONFIGURATION	REGISTER 
;    ; bits 7-2:
;    ;	NOT IMPLEMENTED
;    ;
;    ; bit 0:
;    ;	RWM<1> (Render Write Mode)
;    ;	1 = solid color mode - use WRGB
;    ;	0 = normal frame operation
;    ;
;    ; bit 1:
;    ;	ROI<1> (Render On Interrupt)
;    ;	1 = render on interrup
;    ;	0 = wait for FBCC to be set
;    ;
;RENDER_CON  RES 1	
;    
;	
;; RENDER STATUS REGISTER
;    ; bit 7:
;    ;	FBCC<1> (Frame Buffer Calculations Complete)
;    ;	1 = calculations complete
;    ;	0 = calculations in progress
;    ;
;    ; bit 6:
;    ;	FPSTM<1> (FPS Target Met)
;    ;	1 = FPS target met
;    ;	0 = FPS target not met - calculations may be in progress
;    ;
;    ; bit 5:
;    ;	FRC<1> (Frame Render Complete)
;    ;	1 = frame render from interrupt complete
;    ;	0 = frame rendering still in progress
;    ;
;    ; bit 4:
;    ;	FRH<1> (Frame Render Halted) - not used yet
;    ;	1 = Frame rendering process (interrupt) has been halted to allow for another process to finish before 
;    ;	    the frame is written.
;    ;	0 = Frame rendering process operating normally.
;    ;
;    ; bits 3-0:
;    ;	NOT IMPLEMENTED
;    ;
;RENDER_STATUS	RES 1
;   
;   
;; BUFFER
;; MUST be manually allocated for NUM_LEDS starting at 0x1A0. For each bank, 
;; use 80 bytes (depends on processor). Use L/H notation for 2 banks, L/M/H 
;; for 3, LL/LM/MM/ and so on for more than 3 banks. Will be accessed indirectly.
;BUFFERL	UDATA   0x1A0	
;BUFFERL	RES 80
;BUFFERM	UDATA   0x220
;BUFFERM	RES 80
;BUFFERH	UDATA   0x2A0	
;BUFFERH	RES 20    
;
;	
;;*******************************************************************************
;;			       INITIALIZATION
;;*******************************************************************************
;RENDER	CODE		
; 
;INITIAL:
;; CLOCK CONFIGURATION
;    BANKSEL OSCCON
;    MOVLF   OSCCON, b'11110010'   ; set for extrernal clock
;    
;; PIN INITIALIZATION
;    ;PORTC
;    BANKSEL PORTC
;    CLRF    PORTC		    ; clear PORTC
;    BANKSEL TRISC
;    BCF	    TRISC, WS2813_LAT	    ; set WS2813_PIN as the output pin for serial data
;    BANKSEL SLRCONC
;    CLRF    SLRCONC		    ; allow for maximum slew rate
;    BANKSEL HIDRVC
;    BSF	    HIDRVC, WS2813_HIDR	    ; enable high current drive for C4
;   
;    
;; TIMER1 CONFIGURATION
;    BANKSEL T1CON
;    CLRF    T1CON		    ; set TMR1 to use Fosc as clock - enable TMR1
;				    ; when first frame starts to get written to
;    CLRF    T1GCON		    ; enable T1GE, active high, set gate source 
;				    ; to T1G pin (RA4). RA4 controlled by RA5.
;    BANKSEL TMR1L
;    MOVLF   TMR1L, low TMR1_OFFSET  ; set TMR1 for set FPS 
;    MOVLF   TMR1H, high TMR1_OFFSET ; set TMR1 for set FPS 
;				    
;; INTERRUPT CONFIGURATION
;    BANKSEL PIE1		    
;    BSF	    PIE1, TMR1IE	    ; set Timer1 peripherial interrupt enable
;    BANKSEL INTCON		    
;    BSF	    INTCON, PEIE	    ; allow peripherial interrupts
;    
;    
;    
;; VARIABLE INITIALIZATION
;    BANKSEL WRGB		    ; initalize COLOR variable to solid green
;    MOVLF   WRGB, 0x00		    ; green 
;    MOVLF   WRGB+1, 0x00	    ; red 
;    MOVLF   WRGB+2, 0x00	    ; blue 
;    
;; RENDER CONFIGURATION
;    BANKSEL RENDER_CON
;    MOVLF   RENDER_CON, b'00000011' ; solid color mode and render on interrupt 
;    
;    RETURN    
;	
;    
;    
;;*******************************************************************************
;;			  INTERRUPT SERVICE ROUTINE
;;*******************************************************************************
;INTERRUPT_SERV:
;; FRAME RENDER OR EXTERNAL INTERRUPT
;    BANKSEL PIR1
;    BTFSS   PIR1, TMR1IF	    ; test whether it is a frame render flag
;     GOTO   EXTERN_INT
;    GOTO    RENDER_INT
;    
;EXTERN_INT:
;    PAGESEL EXTERN_INTERRUPT_SERV
;    CALL    EXTERN_INTERRUPT_SERV   ; call external interrupt service routine
;    RETFIE
;    
;RENDER_INT:
;;SKIP THIS FRAME?
;    BANKSEL RENDER_CON
;    BTFSC   RENDER_CON, ROI	    ; check if render on interrupt is clear. Active high. If clear, check FBCC.
;     GOTO   CONTINUE_RENDER 
;    BTFSC   RENDER_STATUS, FBCC	    ; check if frame buffer calculations are complete. Exit interrupt, skip 
;     GOTO   CONTINUE_RENDER	    ; this frame, if frame calculations are incomplete. 
;    RENDER_CLEANUP
;    BANKSEL RENDER_STATUS
;    BSF	    RENDER_STATUS, FRC	    ; indicate that the frame rendering has been skipped
;    RETFIE
;     
;     
;CONTINUE_RENDER:
;;DISABLE PERIPHERAL INTERRUPTS 
;    BANKSEL INTCON		    
;    BCF	    INTCON, PEIE	    
;    
;;CLEANUP
;    RENDER_CLEANUP
;    
;; FRAME PREPARATION
;    BANKSEL RENDER_CON
;    BTFSS   RENDER_CON, RWM
;     GOTO   NORMAL_OPERATION
;    GOTO    SOLID_COLOR
;NORMAL_OPERATION:
;    MOVLF   FSR0H, high FSR_BUFFER_START	; set FSR0 to correct memory location
;    MOVLF   FSR0L, low FSR_BUFFER_START		; for linear addressing
;    GOTO    WRITE
;SOLID_COLOR:
;    MOVLF   FSR0H, high FSR_WRGB		; set FSR0 to WRGB for solid color rendering mode
;    MOVLF   FSR0L, low FSR_WRGB			; 
;    
;; RENDER FRAME
;WRITE:
;    PAGESEL WRITE_FRAME
;    CALL    WRITE_FRAME		    ; display next frame
;   
;; EXIT INTERRUPT
;    BANKSEL RENDER_STATUS
;    BSF	    RENDER_STATUS, FRC	    ; indicate that the frame rendering has completed
;    
;    RETFIE			    ; exit interrupt
;
;    
;;*******************************************************************************
;;				   MAIN
;;*  *	*   *	*   *	*   *	*   *	*   *	*   *	*   *	*   *	*   *  *
;START:
;    PAGESEL INITIAL
;    CALL    INITIAL		    ; initialize PIC
;    PAGESEL EXTERN_INITIAL
;    CALL    EXTERN_INITIAL
;    BANKSEL INTCON
;    BSF	    INTCON, GIE		    ; enable global interrupts now that initialization has completed
;    
;    BANKSEL FRAMECOUNT
;    MOVLF   FRAMECOUNT, 1
;    MOVLF   LEDCOUNT, NUM_LEDS
;    
;    
;;*  *	*   *	*   *	*   *	*   *	*   *	*   *	*   *	*   *	*   *  *
;;			       RENDER_LOOP
;;*******************************************************************************
;RENDER_LOOP:	
;    BANKSEL T1CON
;    BSF	    T1CON, TMR1ON	    ; T1 start counting- start rendering process
;    
;    
;;START FRAME BUFFER CALCULATIONS
;    PAGESEL DO_RENDER
;    CALL    DO_RENDER
;    BANKSEL RENDER_STATUS
;    BSF	    RENDER_STATUS, FBCC	    ; calculations complete
;    
;;WAIT FOR FRAME RENDER TO FINISH
;    BTFSS   RENDER_STATUS, FRC	    ; check whether the frame has completed rendering
;    GOTO    $-1			    ; check again   
;    
;;ENABLE PERIPHERAL INTERRUPTS 
;    BANKSEL INTCON		    
;    BSF	    INTCON, PEIE
;    
;;RENDER CLEANUP				   
;    BCF	    RENDER_STATUS, FBCC
;    BCF	    RENDER_STATUS, FRC
;    GOTO    RENDER_LOOP
; 
;    
;    
;WRITE CODE 
;;*******************************************************************************
;;				WRITE_FRAME
;;*******************************************************************************    
;WRITE_FRAME:
;    BANKSEL WRITE_COUNT
;    MOVLF   WRITE_COUNT, NUM_LEDS   ; copy NUM_LEDS to WRITE_COUNT
;    
;WRITE_LED:
;    BANKSEL RENDER_CON
;    CALL    WS2813_WRITE	    ; write out LED to strip
;;    BTFSC   RENDER_CON, RWM
;;     ADDFSR 0, -3
;    DECFSZ  WRITE_COUNT, F		    
;    GOTO    WRITE_LED		    ; repeat until all LEDs have been written to
;    RETURN
;
;
;
;;*******************************************************************************
;;				 WS2813_WRITE
;;*******************************************************************************
;WS2813_WRITE:
;    ;
;    ;
;    ;
;    ; GREEN
;    BTFSS   WRGB, 7
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 6
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 5
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 4
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 3
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 2
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 1
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB, 0
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    ;
;    ;
;    ;
;    ; RED
;    ADDFSR  0, 1		    ; increment FSR0
;    BTFSS   WRGB+1, 7
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 6
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 5
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 4
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 3
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 2
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 1
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+1, 0
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    ;
;    ;
;    ;
;    ; BLUE
;    BTFSS   WRGB+2, 7
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 6
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 5
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 4
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 3
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 2
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 1
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    BTFSS   WRGB+2, 0
;    GOTO    $+HIGH_SZ
;    BITHIGH
;    GOTO    $+LOW_SZ
;    BITLOW
;    
;    
;    RETURN
;    
;    
;    
;;WS2813_WRITE:
;;    ;
;;    ;
;;    ;
;;    ; GREEN
;;    BTFSS   INDF0, 7
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 6
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 5
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 4
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 3
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 2
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 1
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 0
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    ;
;;    ;
;;    ;
;;    ; RED
;;    ADDFSR  0, 1		    ; increment FSR0
;;    BTFSS   INDF0, 7
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 6
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 5
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 4
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 3
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 2
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 1
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 0
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    ;
;;    ;
;;    ;
;;    ; BLUE
;;    ADDFSR  0, 1		    ; increment FSR0
;;    BTFSS   INDF0, 7
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 6
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 5
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 4
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 3
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 2
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 1
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    BTFSS   INDF0, 0
;;    GOTO    $+HIGH_SZ
;;    BITHIGH
;;    GOTO    $+LOW_SZ
;;    BITLOW
;;    
;;    ADDFSR  0, 1		    ; increment FSR0
;;    
;;    RETURN
;
;
;;HALT_RENDER:
;;; SAVE CONTEXT OF HALT SUBROUTINE
;;    CPYFF   BSR, BSR_HCOPY
;;    CPYFF   PCLATH,PCLATH_HCOPY 
;;    ;MOVLW   5			    
;;    ;ADDWF   PCL				; add to PC halt copy to continue after shadow register restoration
;;; RESTORE SHADOW REGISTERS - context in "DO_RENDER" to allow for the frame buffer calculations to complete.
;;    BANKSEL PCLATH_SHAD
;;    SWAPF   PCLATH_SHAD, W
;;    BANKSEL PCLATH
;;    SWAPF   PCLATH, W
;;    BANKSEL STATUS_SHAD
;;    SWAPF   STATUS_SHAD, W
;;    BANKSEL STATUS
;;    SWAPF   STATUS, W
;;    BANKSEL BSR_SHAD
;;    SWAPF   BSR_SHAD, W
;;    BANKSEL BSR
;;    SWAPF   BSR, W
;;    BANKSEL WREG_SHAD
;;    SWAPF   WREG_SHAD, W
;;    BANKSEL WREG
;;    SWAPF   WREG, W
;;    
;;    RETURN
;;    
;    
;    END