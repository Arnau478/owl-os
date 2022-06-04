#include "keyboard.h"
#include "arch/i686/io.h"
#include "arch/i686/isr.h"
#include <stdio.h>

static void keyboard_callback(Registers *regs){
    uint8_t scancode = i686_inb(0x60);
    printf("Key scancode: %d\n", scancode);
    i686_outb(0x20, 0x20);
}

void i686_Keyboard_Initialize(int freq){
    i686_ISR_RegisterHandler(IRQ(1), keyboard_callback);
}
