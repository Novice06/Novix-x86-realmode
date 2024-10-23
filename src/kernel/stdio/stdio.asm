BITS 16

section _TEXT class=CODE

global _x86_div64_32

_x86_div64_32:
	push bp
	mov bp, sp

	push bx

	mov eax, [bp+8] ; upper bits of the devidend
	mov ecx, [bp+12] ; divisor
	xor edx, edx
	div ecx

	mov bx, [bp+16]
	mov [bx+4], eax ; upper bits of the quotient

	mov eax, [bp+4] ; Lower 32 bits of the dividend
	div ecx

	mov [bx], eax
	mov bx, [bp+18]
	mov [bx], edx

	pop bx
	mov sp, bp

	pop bp
	ret

global _x86_Video_WriteCharTeletype

_x86_Video_WriteCharTeletype:
	push bp
	mov bp, sp

	push bx

	mov ah, 0xe
	mov al, [bp+4]
	mov bh, [bp+6]

	int 0x10

	pop bx
	mov sp, bp

	pop bp
	ret


