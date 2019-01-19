/* 
 * File:   adc1.h
 * Author: 904pa
 *
 * Created on January 18, 2019, 8:37 PM
 */

#ifndef ADC1_H
#define	ADC1_H

void ADC1_Initialize();

#define ADC1_SAMPLING_MODE AD1CON1bits.ASAM
#define MANUAL_SAMPLING 0
#define AUTO_SAMPLING 1

#define ADC1_Interrupt_Enable() (IEC0bits.AD1IE = 1)
#define ADC1_Interrupt_Disable() (IEC0bits.AD1IE = 0)

#define ADC1_ON() (AD1CON1bits.ADON = 1)
#define ADC1_OFF() (AD1CON1bits.ADON = 0)

#define ADC1_PAUSE() (ADC1_SAMPLING_MODE = MANUAL_SAMPLING)
#define ADC1_RESUME() (ADC1_SAMPLING_MODE = AUTO_SAMPLING)

#endif	/* ADC1_H */

