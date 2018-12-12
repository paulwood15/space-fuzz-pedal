

#include "WS2813.h"

uint_fast16_t C0L;                      // WS2813 0-low clock cycles
uint_fast16_t C0H;                      // WS2813 0-high clock cycles
uint_fast16_t C1L;                      // WS2813 1-low clock cycles
uint_fast16_t C1H;                      // WS2813 1-high clock cycles

const float T0L = 1.2;         // WS2813 0-low time (microseconds)
const float T0H = 0.265;          // WS2813 0-high time (microseconds)
const float T1L = 0.3;          // WS2813 1-low time (microseconds)
const float T1H = 1.2;         // WS2813 1-high time (microseconds)
const float TRES = 500;      // WS2813 reset time (microseconds)
const uint_fast16_t correctiveFactor = 4;

//BUG: doesn't work for numbers larger than 32-bits
void WS2813_dispBinary(unsigned long long num, uint16_t n_bits) {
    long buffer[NUM_LEDS] = {0};
    
    // put number binary data into buffer
    for (int i = 0; i < n_bits; i++) {
        if ((num & (1UL << i)) > 0) {
            buffer[i] = 0x00FFFFFF; //white
        }
        else {
            buffer[i] = 0x0000000; //off
        } 
        
        if (i == 31) {
            num = num >> 16;
        }
    }
    
    // fill the rest of the buffer with 0's
    for (int i = n_bits; i < NUM_LEDS; i++) {
        buffer[i] = 0x00FF0000; 
        
        if (i == 31) {
            num = num >> 16;
        }
    }
    
    // display buffer contents
    for (int i = 0; i < NUM_LEDS; i++) {
        WS2813_writeout(WS2813_PIN_LAT_MASK, buffer[i], C0L, C0H, C1L, C1H);
    }
}


void WS2813_calcTimingClockCycles(uint16_t fcy_mhz) {
    C0L = fcy_mhz * T0L;
    C0L -= correctiveFactor;
    
    C0H = fcy_mhz * T0H; 
    C0H -= correctiveFactor;
    
    C1L = fcy_mhz * T1L;
    C1L -= correctiveFactor;
    
    C1H = fcy_mhz * T1H;
    C1H -= correctiveFactor;
}

void WS2813_Initialize(uint16_t fcy_mhz) {
    WS2813_calcTimingClockCycles(fcy_mhz);
}

void WS2813_writeColor(uint32_t color) {
    WS2813_writeout(WS2813_PIN_LAT_MASK, color, C0L, C0H, C1L, C1H);
}
