/* 
 * File:   adc.c
 * Author: 904pa
 *
 * Created on January 18, 2019, 9:05 PM
 */

#include <p33EV256GM102.h>

#include "adc1.h"

void ADC1_Initialize() {
    AD1CON1bits.AD12B = 1;      // 12 bit operation
    AD1CON1bits.FORM = 3;       // Q15 conversion format
    AD1CON1bits.SSRC = 2;       // TMR3 starts conversion
    AD1CON1bits.ASAM = 1;       // starts sampling after last conversion
    
    AD1CON2bits.VCFG = 0;       // AVss and AVdd as voltage references
    AD1CON2bits.SMPI = 15;      // 16 samples per interrupt
    
    AD1CON3bits.ADRC = 1;       // internal RC osc
    AD1CON3bits.SAMC = 5;       // sample time min 3 TAD 
    AD1CON3bits.ADCS = 14;      // conversion time - typ. 15TAD
    
    AD1CHS0bits.CH0NA = 0;      // neg input is VREFL
    AD1CHS0bits.CH0SA = 0;      // pos input is AN0
    
    IEC0bits.AD1IE = 0;         // enable interrupt
}
