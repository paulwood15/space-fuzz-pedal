; CONFIG
#DEFINE WS2813_PIN	RC4	    ; Must use pin with high drive capabilities
#DEFINE WS2813_LAT	LATC4	    ; 
#DEFINE WS2813_HIDR	HIDC4	    ; 
#DEFINE	NUM_LEDS	60	    ; number of LEDs in strip


; REGISTER BIT FIELDS
    ; RENDER_STATUS
    #define	FBCC	7
    #define	FPSTM	6
    #define	FRC	5
    