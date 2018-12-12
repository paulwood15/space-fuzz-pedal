/* 
 * File:   WS2813.h
 * Author: 904pa
 *
 * Created on December 10, 2018, 10:29 PM
 */

#include <stdint.h>

#ifndef WS2813_H
#define	WS2813_H

#define WS2813_PIN_LAT_MASK 0x20
#define NUM_LEDS 60

extern void WS2813_writeout(volatile uint16_t, volatile uint32_t, volatile uint16_t, volatile uint16_t, volatile uint16_t, volatile uint16_t);
void WS2813_dispBinary(unsigned long long, uint16_t);
void WS2813_writeColor(uint32_t);
void WS2813_calcTimingClockCycles(uint16_t);

void WS2813_Initialize(uint16_t);

#endif	/* WS2813_H */

