#include p16f1615.inc
;************************************************************************************
;				    GLOBALS    
;************************************************************************************
    GLOBAL  RSHIFT16
    GLOBAL  LSHIFT16
    GLOBAL  SHIFTNUM
    
    
UTIL_VARS   UDATA   0x5A0
;************************************************************************************
;			      "Div" ROUTINE VARIABLES    
;************************************************************************************
SHIFTNUM	RES 2
    
    

UTIL_PRGM   CODE
;************************************************************************************
;				     ROUTINES    
;************************************************************************************
RSHIFT16:
    LOCAL   LOOP
    BCF	    STATUS, C
    BCF	    STATUS, Z
    BANKSEL WREG
    BTFSC   WREG, 0			; check for odd number - will be ignored
     BSF    STATUS, Z

RSLOOP:
    BANKSEL SHIFTNUM
    BTFSC   SHIFTNUM+1, 0
     BSF    STATUS, C
    LSRF    SHIFTNUM
    LSRF    SHIFTNUM+1
    BTFSC   STATUS, C
     BSF    SHIFTNUM, 7
    BCF	    STATUS, C
    DECFSZ  WREG
     GOTO   RSLOOP
    
    RETURN

    
    
LSHIFT16:
    LOCAL   LOOP
    BCF	    STATUS, C
    BCF	    STATUS, Z
    BANKSEL WREG
    BTFSC   WREG, 0			; check for odd number - will be ignored
     BSF    STATUS, Z

LSLOOP:
    BANKSEL SHIFTNUM
    BTFSC   SHIFTNUM, 7
     BSF    STATUS, C
    LSLF    SHIFTNUM
    LSLF    SHIFTNUM+1
    BTFSC   STATUS, C
     BSF    SHIFTNUM+1, 0
    BCF	    STATUS, C
    DECFSZ  WREG
     GOTO   LSLOOP
    
    RETURN
    
    
    
    
    END

