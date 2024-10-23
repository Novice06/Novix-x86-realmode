bits 16

section _ENTRY CLASS=CODE

extern _cstart_

global entry

entry:
	cli
	mov ax, ds
	mov ss, ax
	mov sp, 0
	mov bp, sp
	sti

	call _cstart_

	cli
	hlt


global _x86_keypress_andReadChar

_x86_keypress_andReadChar:
	push bp
	mov bp, sp

	push bx

	xor ax, ax

wait_key:
	mov ah, 0x1
	int 0x16
	jz wait_key

	mov ah, 0x0 ;clear_buffer
	int 0x16

	mov bx, [bp+4]
	mov [bx], al

	mov bx, [bp+6]
	mov [bx], ah

	pop bx
	
	mov sp, bp
	pop bp
	ret

global _backSpace_handler
_backSpace_handler:
	push bp
	mov bp, sp

	push bx

	mov ah, 0x3
	mov bh, 0
	int 0x10

	or dl, dl
	jnz normal_execution
	dec dh
	mov dl, 79
	jmp set_cursor
normal_execution:
	dec dl

set_cursor:
	mov ah, 0x2
	int 0x10

	mov ah, 0xe
	mov al, [bp+4]
	mov bh, 0
	int 0x10

	mov ah, 0x3
	mov bh, 0
	int 0x10

	or dl, dl
	jnz normal_execution2
	dec dh
	mov dl, 79
	jmp set_cursor2

normal_execution2:
	dec dl

set_cursor2:
	mov ah, 0x2
	int 0x10

	pop bx
	mov sp, bp

	pop bp
	ret
