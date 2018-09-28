/*
 * File:   main.c
 * Author: Paul Wood
 *
 * Created on August 24, 2018, 1:58 PM
 */

/*
 * TODO: resolve interrupt handler warning, simulate and test ADC reading, write frequency magnitude finder
 * scale fft buffer results, assign values to colors based on frequency, and write
 * function to write data out to WS2813 from buffer.
 */

#include "config.h"
// all PIC related includes go above xc.h
#include <xc.h>
#include <libpic30.h>
#include <stdint.h>
#include <dsp.h>
#include <dsp_factors_32b.h>
#include <stdbool.h>

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

#define FFT_SIZE 2048

#define ADC_IVT_ADDRESS 0x00002E


#define BLUE 0x0000FF
#define RED 0xFF0000
#define GREEN 0x00FF00


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

volatile long FFT_Buffer[FFT_SIZE] __attribute__((space(ymemory)));

int buffer_index = 0;

void ADC_init(void);
void TMR3_init(void);

typedef struct {
    volatile uint_fast8_t red;
    volatile uint_fast8_t green;
    volatile uint_fast8_t blue;
} color;

//TODO: Create color enums

void __attribute__((interrupt(irq(ADC_IVT_ADDRESS)), auto_psv))_ADCInterrupt(void) {
    FFT_Buffer[buffer_index]   = (ADC1BUF0, 0); 
    FFT_Buffer[++buffer_index] = (ADC1BUF1, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF2, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF3, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF4, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF5, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF6, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF7, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF8, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUF9, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUFA, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUFB, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUFC, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUFD, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUFE, 0);
    FFT_Buffer[++buffer_index] = (ADC1BUFF, 0);
    buffer_index++;
    
    //tell main when to display information
    
    IFS0bits.AD1IF = 0;
}

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
    AD1CON1bits.FORM = 3;               // Conversion form: converts to signed fractional (Q15)
    AD1CON1bits.SSRC = 2;               // TMR3 starts conversion 
    AD1CON1bits.ASAM = 1;               // auto samples after last conv.
    
//AD1CON2 - ADC CONTROL REGISTER 2
    AD1CON2bits.VCFG = 0;               // AVdd and AVss for voltage reference 
    AD1CON2bits.CSCNA = 0;              // do not scan inputs
    AD1CON2bits.CHPS = 0;               // convert ch0 only
    AD1CON2bits.SMPI = 0b1111;          // Interrupt after the 16th sample
    AD1CON2bits.ALTS = 0;               // always use MUXA input
    
//AD1CON3 - ADC CONTROL REGISTER 3
    AD1CON3bits.ADRC = 0;               // clock derived from system clock
    AD1CON3bits.SAMC = 0;               // don't care
    AD1CON3bits.ADCS = 3;               // ADC conversion clock select to 4*TAD

//AD1CHS0 - ADC CHANNEL SELECT
    AD1CHS0bits.CH0NA = 0;              // set neg ch0 input Vrefl
    AD1CHS0bits.CH0SA = ADC_ANx;        // set pos ch0 input as ADC_ANx
    
    AD1CON4bits.ADDMAEN = 0;            // do not use DMA
    IEC0bits.AD1IE = 1;                 // enable ADC1 interrupt
} 

///*
// * Using ADC with DMA reading ADC1BUF0 into DMA ram area. DMA gets triggered from ADC Conversion complete inetrrupt flag, AD1IF.
// * The ADC is configured to be auto sampled and trigger converted by TMR3 special event to ensure proper sampling frequency for FFT (ADC pg. 20).
// * The ADC starts sampling after last conversion complete. The ADC is only using channel 0 in continuous mode. The ADC will
// * be turned off after FFT_SIZE number of conversions to perform FFT on data, then upon completion of FFT and writing to WS2813,
// * the ADC will be turned on again. 
// * 
// */
//void ADC_init_DMA(void) {
////AD1CON1 - ADC CONTROL REGISTER 1
//    AD1CON1bits.AD12B = 1;              // 1 = 12 bit mode, 0 = 10 bit mode
//    AD1CON1bits.ADDMABM = 1;            // DMA Buffer Build Mode: written in order of conversion
//    AD1CON1bits.FORM = 3;               // Conversion form: converts to signed fractional (Q15)
//    AD1CON1bits.SSRC = 2;               // TMR3 starts conversion 
//    AD1CON1bits.ASAM = 1;               // auto samples after last conv.
//    
////AD1CON2 - ADC CONTROL REGISTER 2
//    AD1CON2bits.VCFG = 0;               // AVdd and AVss for voltage reference 
//    AD1CON2bits.CSCNA = 0;              // do not scan inputs
//    AD1CON2bits.CHPS = 0;               // convert ch0 only
//    AD1CON2bits.SMPI = 0;               // incr. DMA pointer after every sampl/conv
//    AD1CON2bits.ALTS = 0;               // always use MUXA input
//    
////AD1CON3 - ADC CONTROL REGISTER 3
//    AD1CON3bits.ADRC = 0;               // clock derived from system clock
//    AD1CON3bits.SAMC = 0;               // don't care
//    AD1CON3bits.ADCS = 3;              // ADC conversion clock select to 4*TAD
//
////AD1CON4 - ADC CONTROL REGISTER 4
//    AD1CON4bits.DMABL = 4;              // 16 buffer words allocated to analog input
//    
////AD1CHS0 - ADC CHANNEL SELECT
//    AD1CHS0bits.CH0NA = 0;              // set neg ch0 input Vrefl
//    AD1CHS0bits.CH0SA = ADC_ANx;        // set pos ch0 input as ADC_ANx
//    
//    
//} 
///*
// * pg.34
// */
//void DMA_init(void *DMA_buffer) {
////DMA1CON - DMA CONTROL REGISTER
//    DMA1CONbits.CHEN = 1;               // enable DMA1
//    DMA1CONbits.SIZE = 0;               // word transfer size
//    DMA1CONbits.DIR = 0;                // read peripheral to DMA ram
//    DMA1CONbits.HALF = 0;               // init interrupt when all data has been moved
//    DMA1CONbits.NULLW = 0;              // normal operation
//    DMA1CONbits.AMODE = 2;              // Peripheral Indirect Addressing mode
//    DMA1CONbits.MODE = 0;               // continuous mode w/o ping-pong 
//    
////DMA1REQ - DMA CHANNEL 1 IRQ SELECT REGISTER
//    DMA1REQbits.FORCE = 0;              // Automatic DMA transfer initiation by DMA request
//    DMA1REQbits.IRQSEL = (volatile unsigned int)&ADC1BUF0; // Point DMA to ADC1BUF0
//    
////point to buffer location
//    DMA1STAL =  
//}

/*
 * Timer 3 is resonsible for triggering the ADC1 conversion - it sets the ultimate sampinging frequency.
 * 
 */
void TMR3_init(void) {
    TMR3 = 0x0000;
    
    //converts ADC_SAMPLING_PERIOD to seconds -> T*FCY (s * (cycles/s) = #cycles in period)
    //then substracts it from TMR3 register size so it will overflow every #cycles in period
    PR3 = (unsigned int)(0xFFFF - ((0.000001 * ADC_SAMPLING_PERIOD) * FCY));
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

void WS2813_disp_buffer(color *buffer, unsigned int buffer_size) {
    if (buffer == NULL) {
        //WS2813_disp_solidColor({0xFF,0xFF,0xFF});
        return;
    }
    
    for (int i = 0; i < buffer_size; i++) {
        WS2813_write_color(buffer[i]);
    }
    
   
}

//void create_buffer_from_number(color *result_buffer, ){
//
//}

void WS2813_disp_solidColor(color data) {
    for (uint_fast32_t i = NUM_LEDS; i != 0; i--) {
        WS2813_write_color(data);
    }
    __delay_us(RES);
    
    return;
}

//color create_colorStruct(int hex_code) {
//    
//}

void main(void) {
    volatile long *FFT_Results;
    
    System_init();
//    ADC_init();
//    TMR3_init();
//    
//    //turn on TMR3
//    T3CONbits.TON = 1;
//    
//    //turn on ADC
//    AD1CON1bits.ADON = 1;
    
    //ADC validation: read and display info on LED strip
    
    
//    while (1) {
//        while (buffer_index + 1 < FFT_SIZE);        //wait for buffer to fill up
//        IEC0bits.AD1IE = 0;                         //disable AD interrupt
//        
//        //run FFT on data
//        FFT_Results = FFTReal32bIP(FFT_SIZE - 1, FFT_SIZE, (long int *)FFT_Buffer, twdlFctr32b, COEFFS_IN_DATA);
//    
//    }
    

    color test_buffer[3] = {{0xFF,0,0},{0,0xFF,0},{0,0,0xFF}};
    
    while (1) {
        for (int i = 0; i < 20; i++){
            WS2813_disp_buffer(test_buffer,3);
        }
        __delay_us(RES);
    }
    
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
//    unsigned int test = (unsigned int)((0.000001 * ADC_SAMPLING_PERIOD) * FCY);
    return;
}
