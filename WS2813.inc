; CONFIG
#define WS2813_PIN	RC4	    ; Must use pin with high drive capabilities
#define WS2813_LAT	LATC4	    ; 
#define WS2813_HIDR	HIDC4	    ; 
#define	NUM_LEDS	60	    ; number of LEDs in strip
#define GPR_SIZE	0x50
#define	TMR1_OFFSET	0x0000	    ; FPS = f_TMR1TICK / (0xFFFF - TMR1_OFFSET)


; REGISTER BIT FIELDS
    ; RENDER_STATUS
    #define	FBCC	7
    #define	FPSTM	6
    #define	FRC	5
    #define	FRH	4
    
    ; RENDER_CON
    #define	ROI	1
    #define	RWM	0
    
    
	