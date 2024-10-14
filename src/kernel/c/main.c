#include "../include/stdint.h"
#include "../include/stdio.h"

void _cdecl cstart_(){
	printf("hello from C!, %d , %u , %x , %s, %lld", -333, 9979, 0xffac, "hello", -100000ll);
}
