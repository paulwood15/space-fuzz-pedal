
/**
  ADC1 Generated Driver File

  @Company
    Microchip Technology Inc.

  @File Name
    adc1.c

  @Summary
    This is the generated header file for the ADC1 driver using PIC24 / dsPIC33 / PIC32MM MCUs

  @Description
    This header file provides APIs for driver for ADC1.
    Generation Information :
        Product Revision  :  PIC24 / dsPIC33 / PIC32MM MCUs - pic24-dspic-pic32mm : 1.75.1
        Device            :  dsPIC33EV256GM102
    The generated drivers are tested against the following:
        Compiler          :  XC16 v1.35
        MPLAB 	          :  MPLAB X v5.05
*/

/*
    (c) 2016 Microchip Technology Inc. and its subsidiaries. You may use this
    software and any derivatives exclusively with Microchip products.

    THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
    EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
    WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
    PARTICULAR PURPOSE, OR ITS INTERACTION WITH MICROCHIP PRODUCTS, COMBINATION
    WITH ANY OTHER PRODUCTS, OR USE IN ANY APPLICATION.

    IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
    WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
    BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
    FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
    ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
    THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.

    MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF THESE
    TERMS.
*/

/**
  Section: Included Files
*/
#define FCY                 (_XTAL_FREQ / 2)

#include <xc.h>
#include "adc1.h"
#include "tmr3.h"
#include "../WS2813.h"
#include <libpic30.h>
#include "mcc.h"



/**
  Section: Data Type Definitions
*/

/* ADC Driver Hardware Instance Object

  @Summary
    Defines the object required for the maintenance of the hardware instance.

  @Description
    This defines the object required for the maintenance of the hardware
    instance. This object exists once per hardware instance of the peripheral.

 */
typedef struct
{
	uint8_t intSample;
}

ADC_OBJECT;

static ADC_OBJECT adc1_obj;

/**
  Section: Driver Interface
*/


void ADC1_Initialize (void)
{
    // ASAM enabled; ADDMABM disabled; ADSIDL disabled; DONE disabled; SIMSAM Sequential; FORM Fractional result, signed, left-justified; SAMP disabled; SSRC TMR3; AD12B 12-bit; ADON enabled; SSRCG disabled; 

   AD1CON1 = 0x8744;

    // CSCNA enabled; VCFG0 AVDD; VCFG1 AVSS; ALTS disabled; BUFM disabled; SMPI Generates interrupt after completion of every 16th sample/conversion operation; CHPS 1 Channel; 

   AD1CON2 = 0x43C;

    // SAMC 0; ADRC FOSC/2; ADCS 0; 

   AD1CON3 = 0x0;

    // CH0SA OA2/AN0; CH0SB OA2/AN0; CH0NB VREFL; CH0NA AN1; 

   AD1CHS0 = 0x80;

    // CSS26 disabled; CSS25 disabled; CSS24 disabled; CSS27 disabled; 

   AD1CSSH = 0x0;

    // CSS2 disabled; CSS1 disabled; CSS0 enabled; CSS5 disabled; CSS4 disabled; CSS3 disabled; 

   AD1CSSL = 0x1;

    // DMABL Allocates 1 word of buffer to each analog input; ADDMAEN disabled; 

   AD1CON4 = 0x0;

    // CH123SA2 disabled; CH123SB2 CH1=OA2/AN0,CH2=AN1,CH3=AN2; CH123NA disabled; CH123NB CH1=VREF-,CH2=VREF-,CH3=VREF-; 

   AD1CHS123 = 0x0;


   adc1_obj.intSample = AD1CON2bits.SMPI;
   
   // Enabling ADC1 interrupt.
   IEC0bits.AD1IE = 1;
}



void __attribute__ ( ( __interrupt__ , auto_psv ) ) _AD1Interrupt ( void )
{
    TMR3_Stop();
    TMR3_SoftwareCounterClear();
    
            
    WS2813_dispBinary(ADC1BUF0, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF1, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF2, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF3, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF4, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF5, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF6, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF7, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF8, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUF9, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUFA, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUFB, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUFC, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUFD, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUFE, 16);
    __delay_ms(1000);
    WS2813_dispBinary(ADC1BUFF, 16);
    
    
    // clear the ADC interrupt flag
    IFS0bits.AD1IF = false;
    TMR3_Start();
}



/**
  End of File
*/
