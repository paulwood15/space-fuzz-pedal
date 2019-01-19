/*
 * File:   main.c
 * Author: Paul Wood
 *
 * Created on August 24, 2018, 1:58 PM
 */



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

//taken from code configurator
#define T_SAMP 0.000024995      // sampling period (seconds) or 24.995 microseonds 
#define F_SAMP (1 / T_SAMP)     // sampling frequency (Hz)

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
    
    //not done in loop to save instruction cycles 
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
    
    
    if (buffer_index == FFT_SIZE) {
        //start FFT computation and display process
        is_buffer_full = true;
        ADC1_PAUSE();
        ADC1_Interrupt_Disable();
    }
    
     IFS0bits.AD1IF = 0;
}

uint32_t freq_to_color(uint16_t freq) {
    uint16_t temp;       
    
    //frequencies
    const uint16_t f_a = 1000;     // (Hz) red to green start transition
    const uint16_t f_b = 2000;     // (Hz) red to green end transition
    const uint16_t f_c = 3000;     // (Hz) green to blue start transition
    const uint16_t f_d = 4000;     // (Hz) green to blue end transition
    const uint16_t f_e = 5000;     // (Hz) blue to purple start transition
    const uint16_t f_f = 6000;     // (Hz) blue to purple end transition
    
    //slopes
    const float ab_slope = 0xFF / (float)(f_b - f_a);
    const float cd_slope = 0xFF / (float)(f_d - f_c);
    const float ef_slope = 0xFF / (float)(f_f - f_e);
    //const float 
    
    /* Piecewise function */
    //red
    if (freq < f_a) {
        return 0x00FF0000;
    }
    //red to green
    else if (freq < f_b) {
        temp = ab_slope * (freq - f_a);
        return ((uint32_t)(0xFF - temp) << 16) | (temp << 8);
    }
    //green
    else if (freq < f_c) {
        return 0x0000FF00;
    }
    //green to blue
    else if (freq < f_d) {
        temp = cd_slope * (freq - f_c);
        return ((uint32_t)(0xFF - temp) << 8) | temp;
    }
    //blue
    else if (freq < f_e) {
        return 0x000000FF;
    }
    else if (freq < f_f){
        temp = ef_slope * (freq - f_e);
        return ((uint32_t)temp << 16) | 0xFF;
    }
    else {
        return 0x00FF00FF;
    }
    
}


int main(void) {
    fractional fft_results[FFT_SIZE];
    fractional fft_maxValue;
    int16_t fft_maxValue_bin;
    uint16_t max_frequency;
    
    SYSTEM_Initialize();
    WS2813_Initialize(FCY_MHZ);
    
    //fft init
    TwidFactorInit(FFT_LOG2N, &twiddle_factors[0], 0);
    
    //turn on ADC
    ADC1_ON();
    ADC1_PAUSE();       // need to wait for ADC to stablize
    __delay_us(20);     // stablization delay
    ADC1_RESUME();
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
        
        //throw away first result because it is usually ridiculously large
        fft_results[0] = 0;
        
        //get max fft value and bin location
        fft_maxValue = VectorMax(FFT_SIZE / 2, &fft_results[0], &fft_maxValue_bin);
        
        //compute frequency at bin in Hz
        max_frequency = fft_maxValue_bin * (F_SAMP / FFT_SIZE);
        
//        const uint16_t threshold = 1000;        // Hz 
//        if (max_frequency > threshold) {
//            WS2813_write_solidFrame(COLOR_BLUE);
//        }
//        else {
//            WS2813_write_solidFrame(COLOR_RED);
//        }
        
        WS2813_write_solidFrame(freq_to_color(max_frequency));
        
        //clean up for next FFT computation
        buffer_index = 0;
        is_buffer_full = false;
        ADC1_Interrupt_Enable();
        ADC1_RESUME();
    }
    
    return 1;
}
