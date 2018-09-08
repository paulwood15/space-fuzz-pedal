/*
 * File:   main.c
 * Author: Paul Wood
 *
 * Created on August 24, 2018, 1:58 PM
 */

#include "config.h"
// all PIC related includes go above xc.h
#include <xc.h>
#include <libpic30.h>
#include <stdint.h>

#define TEST_LED_ANSEL ANSELAbits.ANSA0     // test led 1
#define TEST_LED_TRIS TRISAbits.TRISA0
#define TEST_LED LATAbits.LATA0
#define TEST_LED2_ANSEL ANSELAbits.ANSA1    // test led 2
#define TEST_LED2_TRIS TRISAbits.TRISA1
#define TEST_LED2 LATAbits.LATA1
//#define TEST_LED3_ANSEL ANSELAbits.ANSA3    // test led 3
#define TEST_LED3_TRIS TRISAbits.TRISA3
#define TEST_LED3 LATAbits.LATA3


#define WS2813_LAT  LATBbits.LATB0
#define WS2813_TRIS TRISBbits.TRISB0
#define WS2813_ANSEL ANSELBbits.ANSB0
#define NUM_LEDS 60

#define T0L 1       // WS2813 0-low (microseconds)
#define T0H 0.28    // WS2813 0-high (microseconds)
#define T1L 0.28    // WS2813 1-low (microseconds)
#define T1H 1       // WS2813 1-high (microseconds)
#define RES 300     //WS2813 reset (microseconds)

#define ADC_ANx 27                  //define x - pin
#define ADC_SAMPLING_PERIOD 400     //microseconds
#define SAMPLE_TIME 8               //num TCY
#define DMA_BUFFER_SIZE 16          // num samples per DMA interrupt - also 
                                    // num words allocated for ANx input - change DMABL

#define FFT_SIZE 2048

#define WS2813_low ({\
    WS2813_LAT = 1; \
    __delay32(19); \
    WS2813_LAT = 0; \
    __delay32(79); \
})

#define WS2813_high ({\
    WS2813_LAT = 1; \
    __delay32(79); \
    WS2813_LAT = 0; \
    __delay32(19); \
})


void ADC_init(void);
void DMA_init(int DMA_buffer_A[DMA_BUFFER_SIZE]);
void TMR3_init(void);

typedef struct {
    volatile uint_fast8_t red;
    volatile uint_fast8_t green;
    volatile uint_fast8_t blue;
} color;


void System_init(void){
    TEST_LED_ANSEL = 0;
    TEST_LED_TRIS = 0;
    TEST_LED = 0;
    TEST_LED2_ANSEL = 0;
    TEST_LED2_TRIS = 0;
    TEST_LED2 = 0;
    TEST_LED3_TRIS = 0;
    TEST_LED3 = 0;
    
/*oscillator configuration*/
    //setup PLL parameters
    CLKDIVbits.FRCDIV = FRC_DIV;
    CLKDIVbits.PLLPRE = PLL_PRE;
    CLKDIVbits.PLLPOST = PLL_POST;
    PLLFBD = PLL_DIV;
    
    //initiate clock switch to FRC w/ PLL 
    __builtin_write_OSCCONH(0x01);
    __builtin_write_OSCCONL(OSCCON | 0x01);
    
    //wait for clock switch to occur
    while (OSCCONbits.COSC!= 0b001);
    TEST_LED = 1;
    
    //wait for PLL lock
    while (OSCCONbits.LOCK!= 1);
    TEST_LED2 = 1;
    
/* WS2813 pin-out configuration*/
    WS2813_TRIS = 0;
    WS2813_LAT = 0;
    WS2813_ANSEL = 0;
    
    
    
    return;
}

void ADC_init(void) {
//AD1CON1 - ADC CONTROL REGISTER 1
    AD1CON1bits.AD12B = 1;              // 1 = 12 bit mode, 0 = 10 bit mode
    AD1CON1bits.ADDMABM = 1;            // DMA buffer written in order of conversion
    AD1CON1bits.FORM = 3;               // converts to signed fractional (Q15)
    AD1CON1bits.SSRC = 2;               // TMR3 starts conversion 
    AD1CON1bits.ASAM = 1;               // auto samples after last conv.
    
//AD1CON2 - ADC CONTROL REGISTER 2
    AD1CON2bits.VCFG = 0;               // AVdd and AVss for voltage reference 
    AD1CON2bits.CSCNA = 0;              // do not scan inputs
    AD1CON2bits.CHPS = 0;               // convert ch0 only
    AD1CON2bits.SMPI = 0;               // incr. DMA pointer after every sampl/conv
    AD1CON2bits.ALTS = 0;               // always use MUXA input
    
//AD1CON3 - ADC CONTROL REGISTER 3
    AD1CON3bits.ADRC = 0;               // clock derived from system clock
    AD1CON3bits.SAMC = 0;               // don't care
    AD1CON3bits.ADCS = 63;              // ADC conversion clock select

//AD1CON4 - ADC CONTROL REGISTER 4
    AD1CON4bits.DMABL = 4;              // 16 buffer words allocated to analog input
    
//AD1CHS0 - ADC CHANNEL SELECT
    AD1CHS0bits.CH0NA = 0;              // set neg ch0 input Vrefl
    AD1CHS0bits.CH0SA = ADC_ANx;        // set pos ch0 input as ADC_ANx
    
    
} 

void DMA_init(int DMA_buffer_A) {
//DMA1CON - DMA CONTROL REGISTER
    DMA1CONbits.SIZE = 0;               // word transfer size
    DMA1CONbits.DIR = 0;                // read peripheral -> DMA
    DMA1CONbits.HALF = 0;               // init interrupt when all data has been moved
    DMA1CONbits.NULLW = 0;              // normal operation
    DMA1CONbits.AMODE = 1;              // indirect w/ post increment
    DMA1CONbits.MODE = 0;               // continuous mode
    
//DMA1REQ - DMA CHANNEL 1 IRQ SELECT REGISTER
    DMA1REQbits.FORCE = 0;              // Automatic DMA transfer initiation by DMA request
    DMA1REQbits.IRQSEL = 0b00001101;    // ADC1 peripheral association
    
}

void TMR3_init(void) {
    TMR3 = 0x0000;
    PR3 = (unsigned int)((0.000001 * ADC_SAMPLING_PERIOD) * FCY);
    IFS0bits.T3IF = 0;                  // clear TMR3 interrupt flag
    IEC0bits.T3IE = 0;                  // disable TMR3 interrupt
}

// to-do: assembly subroutine? 
void __attribute__((optimize(O3))) WS2813_write_color(color data) {
    // WS2813 protocol says that the order should go G, R, B with MSB first
    //green
    for (uint_fast8_t i = 8; i != 0; i--) {
        //test bit
        if ((data.green & 0b10000000) == 0) {
            WS2813_low;
        } else {
            WS2813_high;
        }
        
        data.green = data.green << 0x01U;
    }
    
    //red
    for (uint_fast8_t i = 8; i != 0; i--) {
        //test bit
        if ((data.red & 0b10000000) == 0) {
            WS2813_low;
        } else {
            WS2813_high;
        }
        
        data.red = data.red << 0x01U;
    }
    
    //blue
    for (uint_fast8_t i = 8; i != 0; i--) {
        //test bit
        if ((data.blue & 0b10000000) == 0) {
            WS2813_low;
        } else {
            WS2813_high;
        }
        
        data.blue = data.blue << 0x01U;
    }
    
    return;
}

void WS2813_write_buffer(color* buffer_loc) {
}

void WS2813_disp_solid_color(color data) {
    for (uint_fast32_t i = NUM_LEDS; i != 0; i--) {
        WS2813_write_color(data);
    }
    __delay_us(RES);
    
    return;
}

void main(void) {
    unsigned _Fract[DMA_BUFFER_SIZE] __attribute__((space(dma)));
    
    System_init();
    ADC_init();
    TMR3_init();
    DMA_init(void*);
    
//    color test = {0xFF, 0, 0xFF};
//    WS2813_disp_solid_color(test);
//    
//    while (1) {
//        TEST_LED3 = 0;
//        __delay_ms(1000);
//        TEST_LED3 = 1;
//        __delay_ms(1000);
//    }
//    
    unsigned int test = (unsigned int)((0.000001 * ADC_SAMPLING_PERIOD) * FCY);
    
    while (1);
    
    return;
}
