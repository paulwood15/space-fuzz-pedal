;   
;    .text
;    
;    .bss _pin, 1
;    .equ _pin, #5
;    .global _pin
;    
;    .global _test
;    
;    
;    ;
;    ;
;    ; pin mask		W0
;;     color data	W1, W2
;;     LAT pointer	W3
;;     0 low time	W4
;;     0 high time	W5
;;     1 low time	W6
;    ; 1 high time	W7
;    ;
;    ;
;    _test:
;	ior LATA		; sets bit
;	repeat W5		; bit 0 high time
;	    NOP
;	xor LATA		; toggles bit - already set so it is cleared
;	repeat W4		; bit 0 low time
;	    NOP
;    return
;    
;    .end
;
;
;
;
;
;
;
;
