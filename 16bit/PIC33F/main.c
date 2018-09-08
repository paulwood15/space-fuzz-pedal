/*
 * File:   main.c
 * Author: Paul Wood
 *
 * Created on August 26, 2018, 9:20 AM
 */

#include "config.h"
#include <xc.h>

void main(void) {
    TRISA = 0x0000;
    LATA = 0xFFFF;
    
    while(1);
    return;
}
