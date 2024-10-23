#include "stdio/include/stdint.h"
#include "stdio/include/stdio.h"

#define BUFFER_SIZE 100

void _cdecl x86_keypress_andReadChar(int* ascii, int* scancode);
void _cdecl backSpace_handler(char c);

void _cdecl cstart_(){

	while(1){
        char buffer[BUFFER_SIZE];
        int pos = 0;
		int scancode;
		char c;
		puts(">$");
        while(pos < BUFFER_SIZE){
			x86_keypress_andReadChar((int*)&c, &scancode);
			switch(scancode){
				case 28:
					puts("\r\n");
					goto quit;
					break;
				case 0xe:
					if(pos <= 0)
						continue; //nothing in the buffer
					backSpace_handler(' ');
					pos--;
					break;
				default:
					putc(c);
					buffer[pos] = c;
					pos++;
					break;
			}
        }
	quit:
		printf("\r\n%s\n\r", buffer);
    }
}
