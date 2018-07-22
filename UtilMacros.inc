#include UtilRoutines.inc
#include p16f1615.inc
	
	
MOVLF	MACRO	DEST, LIT
	BANKSEL	DEST
	MOVLW	LIT
	MOVWF	DEST
	ENDM
	
CLRSTAT	MACRO	 
	BCF	STATUS, Z
	BCF	STATUS, C
	BCF	STATUS, DC
	ENDM
	
CPYFF	MACRO	FROM,TO
	BANKSEL	FROM
	MOVF	FROM, W
	BANKSEL	TO
	MOVWF	TO
	ENDM

RSF16	MACRO	NUM, NUMBITS
	MOV16	NUM, SHIFTNUM
	BANKSEL	NUMBITS
	MOVFW	NUMBITS
	PAGESEL	RSHIFT16
	CALL	RSHIFT16
	MOV16	SHIFTNUM, NUM
	ENDM
	
LSF16	MACRO	NUM, NUMBITS
	MOV16	NUM, SHIFTNUM
	BANKSEL	NUMBITS
	MOVFW	NUMBITS
	PAGESEL	LSHIFT16
	CALL	LSHIFT16
	MOV16	SHIFTNUM, NUM
	ENDM
	
;
; http://www.mcmanis.com/chuck/robotics/projects/pic-16bit.htm
;
; These are the psuedo "registers" used by the 16 BIT operations
;        
_REG_A       EQU     H'007E'
_REG_B       EQU     H'007C'

;
; 16 bit move from SRC to DST
;
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
;
; 16 bit unsigned compare, returns Z and C set appropriately
; Compares the registers "CMP_A" and "CMP_B"
; Flag states and what they mean:
;
;       Z true - X & Y are equal
;       C true - X > Y
;       C false - X < Y
;        
CMP16   MACRO   X, Y
        MOV16   X, _REG_A
        SUB16   _REG_A,Y
        MOVF    _REG_A,W
        IORWF   _REG_A+1,W
        ENDM

;
; Initialize a 16 bit value
;
INIT16  MACRO   VAR, CONST
        MOVLW   low (CONST)
        MOVWF   (VAR)
        MOVLW   high (CONST)
        MOVWF   (VAR)+1
        ENDM        

;
; Initialize a 16 bit value to zero
;
CLR16   MACRO   VAR
        CLRF    VAR
        CLRF    VAR+1
        ENDM
        
;
; Macro to do a logical shift right on a 16 bit value
; (0 is shifted into the MSB)
;
LSR16   MACRO   VAR16
        BCF     STATUS, C       ; Clear carry
        RRF     (VAR16)+1,F     ; Rotate high byte right
        RRF     (VAR16),F       ; Rotate low byte right
        ENDM
        
LSL16   MACRO   VAR16
        BCF     STATUS, C       ; Clear carry
        RLF     (VAR16),F       ; Rotate low byte left
        RLF     (VAR16)+1,F     ; Rotate upper byte left
        ENDM        
                
;
; 16 bit unsigned subtraction with carry out.
; Word format is little endian (LSB at lower address)
; Operation is DST = DST - SRC
;
; (This from the "tips and tricks" seminar handout)
;
; DST is replaced, SRC is preserved, Carry is set correctly
;
;
SUB16   MACRO   DST, SRC
        BANKSEL	SRC
	MOVF    SRC,W         ; Get low byte of subtrahend
        BANKSEL	DST
	SUBWF   DST,F         ; Subtract DST(low) - SRC(low)
	BANKSEL	SRC
        MOVF    SRC+1,W       ; Now get high byte of subtrahend
        BTFSS   STATUS,C        ; If there was a borrow, rather than
        INCF    SRC+1,W       ; decrement high byte of dst we inc src
	BANKSEL	DST
        SUBWF   DST+1,F       ; Subtract the high byte and we're done
	ENDM
        
SUBI16  MACRO   DST, CONST
        MOVLW   LOW (CONST)
        SUBWF   (DST), F
        MOVLW   HIGH (CONST)
        BTFSS   STATUS, C
        MOVLW   (HIGH (CONST))+1
        SUBWF   (DST)+1,F
        ENDM
                

;
; 16 bit unsigned addition with carry out.
; Operation: DST = DST + SRC                       
;
; DST is replaced, SRC is preserved, Carry is set correctly
;
ADD16   MACRO   DST,SRC 
        MOVF    (SRC),W         ; Get low byte
        ADDWF   (DST),F         ; Add to destination
        MOVF    (SRC)+1,W       ; Get high byte
        BTFSC   STATUS,C        ; Check for carry
        INCF    (SRC)+1,W       ; Add one for carry
        ADDWF   (DST)+1,F       ; Add high byte into DST
        ENDM

;
; 16 bit Add Immediate
; Operation: DST = DST + Constant
;
; DST is updated, carry is set correctly.
;
ADDI16  MACRO   DST,AD
        MOVLW   LOW (AD)
        ADDWF   DST,F
        MOVLW   HIGH (AD)
        BTFSC   STATUS,C
        MOVLW   (HIGH (AD)) + 1
        ADDWF   (DST)+1,F
        ENDM
;
; Negate 16 bit value
; Find two's complement value of a 16 bit number
;
NEG16   MACRO   DST
        COMF    (DST)
        COMF    (DST)+1
        INC16   DST
        ENDM
                
;
; Increment 16 bit value, sets Z on exit.
;
; Operation: DST++
;
INC16   MACRO   DST        
        INCFSZ  (DST),W         ; Add one to low byte
        DECF    (DST)+1,F       ; No carry (negates next step)
        INCF    (DST)+1,F       ; Add one to high byte
        MOVWF   (DST)           ; Store updated low byte back.
        IORWF   (DST)+1,W       ; Set Z flag
        ENDM

;
; Decrement 16 bit value, sets Z on exit
;        
; Operation: DST--
;
DEC16   MACRO   DST
        DECF    (DST),F         ; Decrement low byte
        INCFSZ  (DST),W         ; Check for underflow
        INCF    (DST)+1,F       ; Update
        DECF    (DST)+1,F       ; Fixup
        MOVF    (DST),W
        IORWF   (DST)+1,W       ; Set Z bit
        ENDM

