#pragma once

#include <stdint.h>

typedef struct {
    uint32_t ds;
    uint32_t edi, esi, ebp, kern_esp, ebx, edx, ecx, eax;
    uint32_t interrupt, error;
    uint32_t eip, cs, cflags, esp, ss;
} __attribute__((packed)) Registers;

void i686_ISR_Initialize();
