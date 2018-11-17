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

//extern void WS2813_writeout(unsigned long, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int);
//extern void test(volatile uint16_t, volatile uint32_t, volatile uint16_t*, volatile uint16_t, volatile uint16_t, volatile uint16_t, volatile uint16_t);
extern void WS2813_writeout(volatile uint16_t, volatile uint32_t, volatile uint16_t, volatile uint16_t, volatile uint16_t, volatile uint16_t);
void WS2813_dispBinary(long long, int);

#define TEST_LED_ANSEL ANSELAbits.ANSA0     // test led 1
#define TEST_LED_TRIS TRISAbits.TRISA0
#define TEST_LED LATAbits.LATA0
#define TEST_LED2_ANSEL ANSELAbits.ANSA1    // test led 2
#define TEST_LED2_TRIS TRISAbits.TRISA1
#define TEST_LED2 LATAbits.LATA1
//#define TEST_LED3_ANSEL ANSELAbits.ANSA3    // test led 3
#define TEST_LED3_TRIS TRISAbits.TRISA3
#define TEST_LED3 LATAbits.LATA3

#define DEBUG_CONTINUE_TRIS TRISBbits.TRISB15
#define DEBUG_CONTINUE_PORT PORTBbits.RB15

#define LAT_bit 4;

const float T0L = 1.2;         // WS2813 0-low time (microseconds)
const float T0H = 0.265;          // WS2813 0-high time (microseconds)
const float T1L = 0.3;          // WS2813 1-low time (microseconds)
const float T1H = 1.2;         // WS2813 1-high time (microseconds)
const float TRES = 500;      // WS2813 reset time (microseconds)
const uint_fast16_t correctiveFactor = 4;

uint_fast16_t C0L;                      // WS2813 0-low clock cycles
uint_fast16_t C0H;                      // WS2813 0-high clock cycles
uint_fast16_t C1L;                      // WS2813 1-low clock cycles
uint_fast16_t C1H;                      // WS2813 1-high clock cycles

#define ADC_ANx 27;                    //define x - pin
float ADC_SAMPLING_PERIOD = 400.0;      //microseconds
const uint_fast16_t  SAMPLE_TIME = 8;               //num TCY

#define FFT_SIZE 2048

#define ADC_IVT_ADDRESS 0x00002E


volatile fractcomplex FFT_Buffer[FFT_SIZE] __attribute__((space(ymemory)));

int buffer_index = 0;

void ADC_init(void);
void TMR3_init(void);

//TODO: Create color enums
//TODO: make some defines into consts

void __attribute__((__interrupt__, no_auto_psv))_AD1Interrupt(void) {
    FFT_Buffer[buffer_index].real   = Q15(ADC1BUF0); 
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF1);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF2);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF3);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF4);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF5);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF6);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF7);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF8);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF9);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFA);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFB);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFC);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFD);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFE);
    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFF);
    buffer_index++;
    
    //DEBUG: display buffer contexts on LED strip
    for (int i = 16; i > 0; i--) {
        if (buffer_index < 16) {
            WS2813_dispBinary((long long)(FFT_Buffer[i].real), 16);
        }
        else {
            WS2813_dispBinary((long long)(FFT_Buffer[buffer_index - i].real), 16);
        }
        
        
        //wait for debug continue pin: low -> high -> low -> activated
        while (DEBUG_CONTINUE_PORT != 1);   // wait for pin to go high
        while (DEBUG_CONTINUE_PORT != 0);   // wait for pin to go low
    }
    
    //TODO: tell main when to display information
    
     IFS0bits.AD1IF = 0;
}

void WS2813_dispBinary(long long num, int n_bits) {
    long buffer[NUM_LEDS] = {0};
    
    // put number binary data into buffer
    for (int i = 0; i < n_bits; i++) {
        if ( (num & (1 << i)) > 0) {
            buffer[i] = 0x00FFFFFF; //white
        }
        else {
            buffer[i] = 0x0000000; //off
        } 
    }
    
    // fill the rest of the buffer with 0's
    for (int i = n_bits; i < 64; i++) {
        buffer[i] = 0x00FF0000; //blue
    }
    
    // display buffer contents
    for (int i = 0; i < NUM_LEDS; i++) {
        WS2813_writeout(WS2813_PIN_LAT_MASK, buffer[i], C0L, C0H, C1L, C1H);
    }
    
}

void calc_WS2813TimingClockCycles(void) {
    C0L = FCY_MHZ * T0L;
    C0L -= correctiveFactor;
    
    C0H = FCY_MHZ * T0H; 
    C0H -= correctiveFactor;
    
    C1L = FCY_MHZ * T1L;
    C1L -= correctiveFactor;
    
    C1H = FCY_MHZ * T1H;
    C1H -= correctiveFactor;
}

void System_init(void){
/*DEBUG*/
    //debug LEDs
    TEST_LED_ANSEL = 0;
    TEST_LED_TRIS = 0;
    TEST_LED = 0;
    TEST_LED2_ANSEL = 0;
    TEST_LED2_TRIS = 0;
    TEST_LED2 = 0;
    TEST_LED3_TRIS = 0;
    TEST_LED3 = 0;
    
    //debug inputs
    DEBUG_CONTINUE_TRIS = 1;
    
    
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
    while (OSCCONbits.COSC != 0b001);
    TEST_LED = 1;
    
    //wait for PLL lock
    while (OSCCONbits.LOCK != 1);
    TEST_LED2 = 1;
    
    //WS2813 pin-out configuration
    WS2813_TRIS = 0;
    WS2813_LAT = 0;
    WS2813_ANSEL = 0;
    
    //WS2813 timing in clock cycles
    calc_WS2813TimingClockCycles();
   
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
    float accumulator = 0;
    
    //converts ADC_SAMPLING_PERIOD to seconds -> T*FCY (s * (cycles/s) = #cycles in period)
    //then substracts it from TMR3 register size so it will overflow every #cycles in period
    accumulator = ADC_SAMPLING_PERIOD * FCY / 1000000;
    PR3 = (unsigned int)(0xFFFF - accumulator);
    IFS0bits.T3IF = 0;                  // clear TMR3 interrupt flag
    IEC0bits.T3IE = 0;                  // disable TMR3 interrupt
}


int main(void) {
    //volatile long *FFT_Results;
    
    
    System_init();
    ADC_init();
    TMR3_init();
    
    //turn on TMR3
    T3CONbits.TON = 1;
    
    //turn on ADC
    AD1CON1bits.ADON = 1;
    
//    uint_fast32_t white = 0x00FFFFFF;
//    uint_fast32_t blue = 0x000000FF;
//    uint_fast32_t green = 0x0000FF00;
//    uint_fast32_t red = 0x00FF0000;
//    
//    uint_fast32_t step = 0x04;
//    uint_fast32_t r_i = 0x8A;
//    uint_fast32_t g_i = 0x15;
//    uint_fast32_t b_i = 0x30;
//    uint_fast32_t color = 0;
//    while (1) {
//        for (uint_fast32_t r = r_i; r < 0xFF; r += step) {
//                for (uint_fast32_t b = b_i; b < 0xFF; b += step) {
//                    color = b + (b << 16);
//                    
//                    for (int i = 0; i < NUM_LEDS; i++) {
//                        WS2813_writeout(WS2813_PIN_LAT_MASK, color, C0L, C0H, C1L, C1H);
//                    }
//                    
//                    __delay_ms(100);
//                }
//            }
//        
//    }
    
        
    __delay_us(TRES);
    


    

    while (1) {
        TEST_LED3 = 0;
        __delay_ms(1000);
        TEST_LED3 = 1;
        __delay_ms(1000);
    }
    
    return 1;
}
