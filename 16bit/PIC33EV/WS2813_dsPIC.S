
    .text
    
    .bss pin, 1
    .equ pin, #5
    
;    /*
;    *
;    
;    * pin mask		W0
;    * 0 low time	W1	
;    * red data		W3[7:0]
;    * green data	W2[15:8]
;    * blue data	W2[7:0]
;    * 0 high time	W4
;    * 1 low time	W5
;    * 1 high time	W6
;    *
;    */
    
    ;//TODO: write remaining routine for LED data output and timing 
    
    .macro BIT_LOW
	ior LATB		;// sets bit
	repeat W4		;// bit 0 high time
	    NOP
	xor LATB		;// toggles bit - already set so it is cleared
	repeat W1		;// bit 0 low time
	    NOP
	.endm
	
    .macro BIT_HIGH
	ior LATB		;// sets bit
	repeat W6		;// bit 1 high time
	    NOP
	xor LATB		;// toggles bit - already set so it is cleared
	repeat W5		;// bit 1 low time
	    NOP
	.endm

    .global _WS2813_writeout
    _WS2813_writeout:
;--------------- green ---------------------------------------------------------
	    btsc W2, #15
		bra G15H
		BIT_LOW
G15H:	    btss W2, #15
		bra G14L
		BIT_HIGH

G14L:	    btsc W2, #14
		bra G14H
		BIT_LOW
G14H:	    btss W2, #14
		bra G13L
		BIT_HIGH

G13L:	    btsc W2, #13
		bra G13H
		BIT_LOW
G13H:	    btss W2, #13
		bra G12L
		BIT_HIGH

G12L:	    btsc W2, #12
		bra G12H
		BIT_LOW
G12H:	    btss W2, #12
		bra G11L
		BIT_HIGH

G11L:	    btsc W2, #11
		bra G11H
		BIT_LOW
G11H:	    btss W2, #11
		bra G10L
		BIT_HIGH

G10L:	    btsc W2, #10
		bra G10H
		BIT_LOW
G10H:	    btss W2, #10
		bra G9L
		BIT_HIGH

G9L:	    btsc W2, #9
		bra G9H
		BIT_LOW
G9H:	    btss W2, #9
		bra G8L
		BIT_HIGH

G8L:	    btsc W2, #8
		bra G8H
		BIT_LOW
G8H:	    btss W2, #8
		bra R7L
		BIT_HIGH

    ;-------------- red -----------------------------------------------------------

R7L:	    btsc W3, #7
		bra R7H
		BIT_LOW
R7H:	    btss W3, #7
		bra R6L
		BIT_HIGH

R6L:	    btsc W3, #6
		bra R6H
		BIT_LOW
R6H:	    btss W3, #6
		bra R5L
		BIT_HIGH

R5L:	    btsc W3, #5
		bra R5H
		BIT_LOW
R5H:	    btss W3, #5
		bra R4L
		BIT_HIGH

R4L:	    btsc W3, #4
		bra R4H
		BIT_LOW
R4H:	    btss W3, #4
		bra R3L
		BIT_HIGH

R3L:	    btsc W3, #3
		bra R3H
		BIT_LOW
R3H:	    btss W3, #3
		bra R2L
		BIT_HIGH

R2L:	    btsc W3, #2
		bra R2H
		BIT_LOW
R2H:	    btss W3, #2
		bra R1L
		BIT_HIGH

R1L:	    btsc W3, #1
		bra R1H
		BIT_LOW
R1H:	    btss W3, #1
		bra R0L
		BIT_HIGH

R0L:	    btsc W3, #0
		bra R0H
		BIT_LOW
R0H:	    btss W3, #0
		bra B7L
		BIT_HIGH

    ;-------------- blue -----------------------------------------------------------

B7L:	    btsc W2, #7
		bra B7H
		BIT_LOW
B7H:	    btss W2, #7
		bra B6L
		BIT_HIGH

B6L:	    btsc W2, #6
		bra B6H
		BIT_LOW
B6H:	    btss W2, #6
		bra B5L
		BIT_HIGH

B5L:	    btsc W2, #5
		bra B5H
		BIT_LOW
B5H:	    btss W2, #5
		bra B4L
		BIT_HIGH

B4L:	    btsc W2, #4
		bra B4H
		BIT_LOW
B4H:	    btss W2, #4
		bra B3L
		BIT_HIGH

B3L:	    btsc W2, #3
		bra B3H
		BIT_LOW
B3H:	    btss W2, #3
		bra B2L
		BIT_LOW

B2L:	    btsc W2, #2
		bra B2H
		BIT_LOW
B2H:	    btss W2, #2
		bra B1L
		BIT_LOW

B1L:	    btsc W2, #1
		bra B1H
		BIT_LOW
B1H:	    btss W2, #1
		bra B0L
		BIT_LOW

B0L:	    btsc W2, #0
		bra B0H
		BIT_LOW
B0H:	    btss W2, #0
		bra DONE
		BIT_LOW
DONE:	    
    return
    .end

