#include "../include/stdio.h"
#include "../include/print.h"

void putc(char c)
{
	x86_Video_WriteCharTeletype(c,0);
}

void puts(const char* s)
{
	while (*s)
	{
		putc(*s);
		s++;
	}
}

void puts_f(const char far* s){
	while (*s){
		putc(*s);
		s++;
	}
}

void _cdecl printf(const char* fmt, ...){
	int* argp = (int*)&fmt;
	int state = PRINTF_STATE_START;
	int length = PRINTF_LENGTH_START;
	int base = 10;
	bool sign = false;

	argp++;
	while(*fmt){
		switch(state){
			case PRINTF_STATE_START:
				if(*fmt == '%'){
					state = PRINTF_STATE_LENGTH;
				}else{
					putc(*fmt);
				}
				break;
			case PRINTF_STATE_LENGTH:
				if(*fmt == 'l'){
					state = PRINTF_STATE_LONG;
					length = PRINTF_LENGTH_LONG;
				}else if(*fmt == 'h'){
					state = PRINTF_STATE_SHORT;
					length = PRINTF_LENGTH_SHORT;
				}else{
					goto PRINTF_STATE_SPEC_;
				}
				break;
			case PRINTF_STATE_SHORT:
				if(*fmt == 'h'){
					state = PRINTF_STATE_SPEC;
					length = PRINTF_LENGTH_SHORT_SHORT;
				}else{
					goto PRINTF_STATE_SPEC_;
				}
				break;
			case PRINTF_STATE_LONG:
				if(*fmt == 'l'){
					state = PRINTF_STATE_SPEC;
					length = PRINTF_LENGTH_LONG_LONG;
				}else{
					goto PRINTF_STATE_SPEC_;
				}
				break;
			case PRINTF_STATE_SPEC:
				PRINTF_STATE_SPEC_:
				switch(*fmt){
					case 'c':
						putc(*(char*)argp);
						argp++;
						break;
					case 's':
						if (length == PRINTF_LENGTH_LONG || length == PRINTF_LENGTH_LONG_LONG){
                            puts_f(*(const char far**)argp);
                            argp += 2;
                        }else{
                            puts(*(const char **)argp);
                            argp++;
                        }
						break;
					case '%':
						putc('%');
						break;
					case 'd':
					case 'i':
						base = 10;
                        sign = true;
                        argp = printf_number(argp, length, sign, base);
						break;
					case 'u':
						base = 10;
                        sign = false;
                        argp = printf_number(argp, length, sign, base);
						break;
					case 'X':
                    case 'x':
                    case 'p':
						base = 16;
                        sign = false;
                        argp = printf_number(argp, length, sign, base);
						break;
					case 'o':
						base = 8;
                        sign = false;
                        argp = printf_number(argp, length, sign, base);
						break;
					default:
						break;
				}
				
				state = PRINTF_STATE_START;
            	length = PRINTF_LENGTH_START;
				break;
		}

		fmt++;
	}
}

const char possibleChars[] = "0123456789abcdef";
int* printf_number(int* argp, int length, bool sign, int base){
	char buffer[32];
	unsigned long long number;
	int number_sign = 1;
	int pos = 0;

	switch(length){
        case PRINTF_LENGTH_START:
		case PRINTF_LENGTH_SHORT:
		case PRINTF_LENGTH_SHORT_SHORT:
			if(sign){
				int n = *argp;
				if(n < 0){
					n = -n;
					number_sign = -1;
				}
				number = (unsigned long long) n;
			}else{
				number = *(unsigned int*)argp;
			}
			argp++;
			break;
		case PRINTF_LENGTH_LONG:
			if(sign){
				long int n = *(long int *)argp;
				if(n < 0){
					n = -n;
					number_sign = -1;
				}
				number = (unsigned long long) n;
			}else{
				number = *(unsigned long int*)argp;
			}
			argp += 2;
			break;
		case PRINTF_LENGTH_LONG_LONG:
			if(sign){
				long long int n = *(long long int *)argp;
				if(n < 0){
					n = -n;
					number_sign = -1;
				}
				number = (unsigned long long) n;
			}else{
				number = *(unsigned long long int*)argp;
			}
			argp += 4;
			break;
	}
	
	do{
		uint32_t rem;
        x86_div64_32(number, base, &number, &rem);
        buffer[pos++] = possibleChars[rem];
	}while(number > 0);

	if(sign && number_sign < 0)
		buffer[pos++] = '-';

	while(--pos >= 0)
		putc(buffer[pos]);

	return argp;
}
