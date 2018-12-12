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

//cycle frequency = oscillator frequency / 2
#define FCY                 (_XTAL_FREQ / 2)
#define FCY_MHZ             (_XTAL_FREQ / 2000000)

#include "mcc_generated_files/mcc.h"
#include <libpic30.h>
#include <stdint.h>
#include <dsp.h>
#include <dsp_factors_32b.h>
#include <stdbool.h>
#include "WS2813.h"

#define TEST_LED_ANSEL      ANSELAbits.ANSA0     // test led 1
#define TEST_LED_TRIS       TRISAbits.TRISA0
#define TEST_LED            LATAbits.LATA0
#define TEST_LED2_ANSEL     ANSELAbits.ANSA1    // test led 2
#define TEST_LED2_TRIS      TRISAbits.TRISA1
#define TEST_LED2           LATAbits.LATA1
//#define TEST_LED3_ANSEL   ANSELAbits.ANSA3    // test led 3
#define TEST_LED3_TRIS      TRISAbits.TRISA3
#define TEST_LED3           LATAbits.LATA3

#define DEBUG_CONTINUE_TRIS TRISBbits.TRISB15
#define DEBUG_CONTINUE_PORT PORTBbits.RB15

#define LAT_bit 4;


#define FFT_SIZE 2048
volatile fractcomplex FFT_Buffer[FFT_SIZE] __attribute__((space(ymemory)));
int buffer_index = 0;


//TODO: Create color enums
//TODO: make some defines into consts

//void __attribute__((__interrupt__, no_auto_psv))_AD1Interrupt(void) {
//    FFT_Buffer[buffer_index].real   = Q15(ADC1BUF0); 
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF1);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF2);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF3);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF4);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF5);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF6);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF7);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF8);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUF9);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFA);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFB);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFC);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFD);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFE);
//    FFT_Buffer[++buffer_index].real = Q15(ADC1BUFF);
//    buffer_index++;
//    
//    //DEBUG: display buffer contexts on LED strip
//    for (int i = 16; i > 0; i--) {
//        if (buffer_index < 16) {
//            WS2813_dispBinary((long long)(FFT_Buffer[i].real), 16);
//        }
//        else {
//            WS2813_dispBinary((long long)(FFT_Buffer[buffer_index - i].real), 16);
//        }
//        
//        
//        //wait for debug continue pin: low -> high -> low -> activated
//        while (DEBUG_CONTINUE_PORT != 1);   // wait for pin to go high
//        while (DEBUG_CONTINUE_PORT != 0);   // wait for pin to go low
//    }
//    
//    //TODO: tell main when to display information
//    
//     IFS0bits.AD1IF = 0;
//}


//void System_init(void){
///*DEBUG*/
//    //debug LEDs
//    TEST_LED_ANSEL = 0;
//    TEST_LED_TRIS = 0;
//    TEST_LED = 0;
//    TEST_LED2_ANSEL = 0;
//    TEST_LED2_TRIS = 0;
//    TEST_LED2 = 0;
//    TEST_LED3_TRIS = 0;
//    TEST_LED3 = 0;
//    
//    //debug inputs
//    DEBUG_CONTINUE_TRIS = 1;
//    
//    
///*oscillator configuration*/
//    //setup PLL parameters
//    CLKDIVbits.FRCDIV = FRC_DIV;
//    CLKDIVbits.PLLPRE = PLL_PRE;
//    CLKDIVbits.PLLPOST = PLL_POST;
//    PLLFBD = PLL_DIV;
//    
//    //initiate clock switch to FRC w/ PLL 
//    __builtin_write_OSCCONH(0x01);
//    __builtin_write_OSCCONL(OSCCON | 0x01);
//    
//    //wait for clock switch to occur
//    while (OSCCONbits.COSC != 0b001);
//    TEST_LED = 1;
//    
//    //wait for PLL lock
//    while (OSCCONbits.LOCK != 1);
//    TEST_LED2 = 1;
//    
//    //WS2813 pin-out configuration
//    WS2813_TRIS = 0;
//    WS2813_LAT = 0;
//    WS2813_ANSEL = 0;
//    
//    //WS2813 timing in clock cycles
//    calc_WS2813TimingClockCycles();
//   
//    return;
//}


int main(void) {
    //volatile long *FFT_Results;
    
    
    SYSTEM_Initialize();
    WS2813_Initialize(FCY_MHZ);
    
    //turn on TMR3
    T3CONbits.TON = 1;
    //turn on ADC
    AD1CON1bits.ADON = 1;
    
    
    while (1) {
    }
    
    return 1;
}
