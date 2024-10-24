#pragma once
#include "stdint.h"

void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);
void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotientOut, uint32_t* remainderOut);


void putc(char c);
void puts(const char* c);

void puts_f(const char far* s);
void _cdecl printf(const char* fmt, ...);
int* printf_number(int* argp, int length, bool sign, int base);

#define PRINTF_STATE_START 0
#define PRINTF_STATE_LENGTH 1
#define PRINTF_STATE_SHORT 2
#define PRINTF_STATE_LONG 3
#define PRINTF_STATE_SPEC 4

#define PRINTF_LENGTH_START 0
#define PRINTF_LENGTH_SHORT 1
#define PRINTF_LENGTH_SHORT_SHORT 2
#define PRINTF_LENGTH_LONG 3
#define PRINTF_LENGTH_LONG_LONG 4
