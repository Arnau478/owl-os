#include "timer.h"
#include "arch/i686/io.h"
#include "arch/i686/isr.h"
#include <stdio.h>

void timer_callback(Registers *regs){
    printf("TICK!\n");
    i686_outb(0x20, 0x20);
}

void i686_Timer_Initialize(int freq){
    i686_ISR_RegisterHandler(32, timer_callback);
    uint32_t divisor = 1193180 / freq;
    uint8_t low  = (uint8_t)(divisor & 0xFF);
    uint8_t high = (uint8_t)( (divisor >> 8) & 0xFF);
    i686_outb(0x43, 0x36);
    i686_outb(0x40, low);
    i686_outb(0x40, high);
}
