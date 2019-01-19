/* 
 * File:   WS2813.h
 * Author: 904pa
 *
 * Created on December 10, 2018, 10:29 PM
 */

#include <stdint.h>
#include "mcc_generated_files/clock.h"
#include <libpic30.h>

#ifndef WS2813_H
#define	WS2813_H

#define WS2813_PIN_LAT_MASK 0x20
#define NUM_LEDS 60

#define COLOR_RED       0x00FF0000
#define COLOR_GREEN     0x0000FF00
#define COLOR_BLUE      0x000000FF

extern void WS2813_writeout(volatile uint16_t, volatile uint32_t, volatile uint16_t, volatile uint16_t, volatile uint16_t, volatile uint16_t);
void WS2813_dispBinary(unsigned long long, uint16_t);
void WS2813_calcTimingClockCycles(uint16_t);

void WS2813_write_color(uint32_t);
void WS2813_write_solidFrame(uint32_t);

void WS2813_Initialize(uint16_t);

#endif	/* WS2813_H */

