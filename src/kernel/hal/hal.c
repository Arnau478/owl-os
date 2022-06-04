#include "hal.h"
#include <arch/i686/gdt.h>
#include <arch/i686/idt.h>
#include <arch/i686/isr.h>
#include <arch/i686/timer.h>
#include <arch/i686/keyboard.h>

void HAL_Initialize(){
    i686_GDT_Initialize();
    i686_IDT_Initialize();
    i686_ISR_Initialize();
    i686_Timer_Initialize(50);
    i686_Keyboard_Initialize();
}
