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
TGRH	EQU 0x1FF + TRIGGER_OFF	    ; signal coming in biased to 2.5V w/ range [0V, 5V] 
TGRL	EQU 0x1FF - TRIGGER_OFF	    ; 2.5V corresponds to 0x3FF / 2 = 0x1FF
 
    
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

; ADC CONFIG
    BANKSEL ADCON1
    MOVLF   ADCON1, b'10000000'		; right justified, Fosc/2, VDD ref
    
; ADC INTERRUPT CONFIG
    BANKSEL PIE1
    BSF	    PIE1, ADIE			; enable ADC interrupt
    
; REGISTER CONFIG
    INIT16  MIN_WAV, 0x1FF
    INIT16  MAX_WAV, 0x1FF
    CLR16   DELTA_T
    
;TODO: ADC start conversion
    
    RETURN
    
 
;*******************************************************************************
;			    EXTERN_INTERRUPT_SERV
;*******************************************************************************
EXTERN_INTERRUPT_SERV:
    ;TODO: determine analog characteristics, then start new adc conversion, clear flags
     
    RETURN
    
    
    

    
;*******************************************************************************
;				 DO_RENDER
;*******************************************************************************
DO_RENDER:
    ;TODO: determine color based on analog characteristics
    
    RETURN
    
    
    
    END