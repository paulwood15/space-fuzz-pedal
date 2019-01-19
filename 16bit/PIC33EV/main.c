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


#define FFT_SIZE 1024
#define FFT_LOG2N 10
#define RESULT_SCALE Q15(0.5)

fractcomplex fft_buffer[FFT_SIZE] __attribute__((space(ymemory), aligned(FFT_SIZE*4)));
fractcomplex twiddle_factors[FFT_SIZE/2]__attribute__((space(xmemory)));
uint16_t buffer_index = 0;
bool is_buffer_full = false;

#define TEMP_BUF_SIZE 16
fractional temp_buffer[TEMP_BUF_SIZE];
uint8_t temp_index;


void __attribute__((__interrupt__, no_auto_psv))_AD1Interrupt(void) {
    // ADC results are in signed fractional format, Q15, but range from [-1,+0.999], and 
        // the fft function requires a range of +-0.5 to avoid overflow
    
    temp_index = 0;
    temp_buffer[temp_index] = ADC1BUF0;
    temp_buffer[++temp_index] = ADC1BUF1;
    temp_buffer[++temp_index] = ADC1BUF2;
    temp_buffer[++temp_index] = ADC1BUF3;
    temp_buffer[++temp_index] = ADC1BUF4;
    temp_buffer[++temp_index] = ADC1BUF5;
    temp_buffer[++temp_index] = ADC1BUF6;
    temp_buffer[++temp_index] = ADC1BUF7;
    temp_buffer[++temp_index] = ADC1BUF8;
    temp_buffer[++temp_index] = ADC1BUF9;
    temp_buffer[++temp_index] = ADC1BUFA;
    temp_buffer[++temp_index] = ADC1BUFB;
    temp_buffer[++temp_index] = ADC1BUFC;
    temp_buffer[++temp_index] = ADC1BUFD;
    temp_buffer[++temp_index] = ADC1BUFE;
    temp_buffer[++temp_index] = ADC1BUFF;
    
    VectorScale(TEMP_BUF_SIZE, &temp_buffer[0], &temp_buffer[0], RESULT_SCALE);
    
    fft_buffer[buffer_index].real = temp_buffer[0];
    fft_buffer[++buffer_index].real = temp_buffer[1];
    fft_buffer[++buffer_index].real = temp_buffer[2];
    fft_buffer[++buffer_index].real = temp_buffer[3];
    fft_buffer[++buffer_index].real = temp_buffer[4];
    fft_buffer[++buffer_index].real = temp_buffer[5];
    fft_buffer[++buffer_index].real = temp_buffer[6];
    fft_buffer[++buffer_index].real = temp_buffer[7];
    fft_buffer[++buffer_index].real = temp_buffer[8];
    fft_buffer[++buffer_index].real = temp_buffer[9];
    fft_buffer[++buffer_index].real = temp_buffer[10];
    fft_buffer[++buffer_index].real = temp_buffer[11];
    fft_buffer[++buffer_index].real = temp_buffer[12];
    fft_buffer[++buffer_index].real = temp_buffer[13];
    fft_buffer[++buffer_index].real = temp_buffer[14];
    fft_buffer[++buffer_index].real = temp_buffer[15];
    buffer_index++;
    
    
    //DEBUG: display buffer contexts on LED strip
//    for (int i = 16; i > 0; i--) {
//        if (buffer_index < 16) {
//            WS2813_dispBinary((long long)(fft_buffer[i].real), 16);
//        }
//        else {
//            WS2813_dispBinary((long long)(fft_buffer[buffer_index - i].real), 16);
//        }
//        
//        
//        //wait for debug continue pin: low -> high -> low -> activated
//        while (DEBUG_CONTINUE_PORT != 1);   // wait for pin to go high
//        while (DEBUG_CONTINUE_PORT != 0);   // wait for pin to go low
//    }
    
    if (buffer_index == FFT_SIZE) {
        //start FFT computation and display process
        is_buffer_full = true;
        ADC1_PAUSE();
        ADC1_Interrupt_Disable();
    }
    
     IFS0bits.AD1IF = 0;
}


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
    fractional fft_results[FFT_SIZE];
    
    SYSTEM_Initialize();
    WS2813_Initialize(FCY_MHZ);
    
    //fft init
    TwidFactorInit(FFT_LOG2N, &twiddle_factors[0], 0);
    
    //turn on ADC
    ADC1_ON();
    ADC1_Interrupt_Enable();
    
    //turn on TMR3
    TMR3_Start();
    
    //main loop
    while (1) {
        while (!is_buffer_full);        // wait for buffer to fill up
        //TODO: vector scale (being done in interrupt)(x), fft compute (x), bit reversal (x), complex magnitude (x), vectorMax ( )
        
        FFTComplexIP(FFT_LOG2N, &fft_buffer[0], &twiddle_factors[0], COEFFS_IN_DATA);    
        BitReverseComplex(FFT_LOG2N, &fft_buffer[0]);
        SquareMagnitudeCplx(FFT_SIZE, &fft_buffer[0], &fft_results[0]);
        
        //clean up for next FFT computation
        buffer_index = 0;
        is_buffer_full = false;
        ADC1_Interrupt_Enable();
        ADC1_RESUME();
    }
    
    return 1;
}


//    AD1CON1bits.SAMP = 1; // Start sampling
//    __delay_us(10); // Wait for sampling time (10us)
//    AD1CON1bits.SAMP = 0; // Start the conversion
//    while (!AD1CON1bits.DONE); // Wait for the conversion to complete
//    ADCValue = ADC1BUF0; // Read the conversion result      
//    
//    while (1) {
//        ADCValue = ADCValue;
//    }
    