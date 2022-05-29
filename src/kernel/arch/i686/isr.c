#include "isr.h"
#include "idt.h"
#include "gdt.h"
#include <stdio.h>

void i686_ISR_InitializeGates();

void i686_ISR_Initialize(){
    i686_ISR_InitializeGates();
    
    for(int i = 0; i < 256; i++){
        i686_IDT_EnableGate(i);
    }
}

void __attribute__((cdecl)) i686_ISR_Handler(Registers *regs){
    printf("Interrupt: %d", regs->interrupt);
}
