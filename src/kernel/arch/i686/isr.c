#include "isr.h"
#include "idt.h"
#include "gdt.h"
#include "io.h"
#include <stdio.h>
#include <stddef.h>

ISRHandler g_ISRHandlers[256];

static const char *const g_Exceptions[] = {
    "Divide by zero error",
    "Debug",
    "Non-maskable interrupt",
    "Breakpoint",
    "Overflow",
    "Bound range exceeded",
    "Invalid opcode",
    "Device not available",
    "Double fault",
    "Coprocessor segment overrun",
    "Invalid TTS",
    "Segment not present",
    "Stack-segment fault",
    "General protection fault",
    "Page fault",
    "",
    "x87 floating point exception",
    "Alignment check",
    "Machine check",
    "SIMD floating-point exception",
    "Virtualization exception",
    "Control protection exception",
    "",
    "",
    "",
    "",
    "",
    "",
    "Hypervisor injection exception",
    "VMM communication exception",
    "Security exception",
    ""
};

void i686_ISR_InitializeGates();

void i686_ISR_Initialize(){
    i686_ISR_InitializeGates();
    
    for(int i = 0; i < 256; i++){
        i686_IDT_EnableGate(i);
    }
}

void __attribute__((cdecl)) i686_ISR_Handler(Registers *regs){
    if(g_ISRHandlers[regs->interrupt] != NULL){
        g_ISRHandlers[regs->interrupt](regs);
    }
    else if(regs->interrupt >= 32){
        printf("Unhandled interrupt %d!\n", regs->interrupt);
    }
    else{
        printf("Unhandled interrupt %d %s\n", regs->interrupt, g_Exceptions[regs->interrupt]);
        printf("  eax=%x ebx=%x ecx=%x edx=%x esi=%x edi=%x\n", regs->eax, regs->ebx, regs->esi, regs->edi);
        printf("  esp=%x ebp=%x eip=%x eflags=%x cs=%x ds=%x ss=%x\n", regs->esp, regs->ebp, regs->eip, regs->eflags, regs->cs, regs->ds, regs->ss);
        printf("  interrupt=%d errorcode=%x\n", regs->interrupt, regs->error);
        printf("!!! KERNEL PANIC !!!\n");
        i686_Panic();
    }
}
