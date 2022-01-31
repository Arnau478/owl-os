#pragma once

#include <stdint.h>

typedef uint8_t vga_col16_t;

void clrscr();
void putc(char c);
void puts(const char *str);
void printf(const char *fmt, ...);
void print_buffer(const char *msg, const void* buffer, uint32_t count);
void setcolor(vga_col16_t col);