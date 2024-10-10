BITS 16

section _TEXT class=CODE

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


