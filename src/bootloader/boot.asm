org 0x7c00
bits 16

jmp short main
nop

;*********************************************
;    BIOS Parameter Block (BPB) for FAT12
;*********************************************

bpb_oem:					db 'MSWIN4.1'
bpb_bytes_per_sector:		dw 512
bpb_sectors_per_cluster:	db 1
bpb_reserved_sectors:		dw 1
bpb_fat_count:				db 2
bpb_dir_entries_count:		dw 0xe0
bpb_total_sectors:			dw 2880
bpb_media_descriptor_type:	db 0xf0
bpb_sectors_per_fat:		dw 9
bpb_sectors_per_track:		dw 18
bpb_heads:					dw 2
bpb_hidden_sectors:			dd 0
bpb_large_sector_count:		dd 0

ebr_drive_number:			db 0
							db 0
ebr_signature:				db 0x29
ebr_volume_id:				db 0x12, 0x34, 0x56, 0x78
ebr_volume_label:			db "VICE OS    "
ebr_system_id:				db "FAT12   "

main:
	xor ax, ax
	mov ds, ax
	mov es, ax

	mov ss, ax
	mov ax, 0x7c00
	mov sp, ax

	mov si, msg
	call print_boot_screen
	hlt

	mov si, file_name
	mov ax, KERNEL_SEGMENT
	mov es, ax ; kernel segment
	mov di, 0 ; kernel offset
	call loadFile_fromFat

	mov ds, ax ; setting up the data segment of the kernel
	jmp KERNEL_SEGMENT:0x0 ;jump to the kernel

halt:
	jmp halt

;=========================================
;load the a file from a fat12 partition
;input: 
;	- file name in si
;	- memory segment in es
;	- memory offset in di
;output: es:di
;=========================================
loadFile_fromFat:
	push si
	push di
	push es
	push ax
	push bx
	push cx

	;##########################
	;loading the root dir table
	;##########################
	push di ; because it contain the file offset
	push es ; because it contain the file segment
	xor ax, ax
	mov es, ax

	mov ax, 19
	mov bx, 14
	mov di, ROOTDIR_AND_FAT_OFFSET
	call disk_read

	;########################################
	;searching for the file in the root table
	;########################################
	xor bx, bx ; init the counter for search_file
search_file:
	push si
	push di
	
	mov cx, 11 ; file name length for fat12 (counter loop for repe)
	repe cmpsb

	pop di
	pop si

	je file_found

	add di, 32 ; next dir entry
	inc bx
	cmp bx, [bpb_dir_entries_count]
	jl search_file

	jmp file_not_found

file_not_found:
	mov si, msg_file_not_found
	call print
	jmp halt

file_found:
	mov cx, [di+26] ; first logical cluster filled
	mov [file_cluster], cx

	;##########################
	;loading the fat table
	;##########################
	mov ax, 1
	mov bx, 18
	mov di, ROOTDIR_AND_FAT_OFFSET ; we just override the root dir table
	call disk_read

	pop es ; restore the file segment
	pop di ; restore the file offset

file_cluster_loop:
	mov ax, [file_cluster]
	add ax, 31
	mov bx, [bpb_sectors_per_cluster]
	call disk_read
	add di, [bpb_bytes_per_sector] ;adding the size of the read data to avoid overwriting existing data

	;#############################################################################################
	;logically, the next cluster is located at he entry file_cluster * 12,
	;and in memory we can only read in multiples of 8bits at a time (bytes)
	;Therefore 2 FAT entries are stored in 3 bytes, to detrmine which byte to start reading from,
	;we use the formula fat_offset = fat_offset + (file_cluster * 12) / 8 if the division is even,
	;it means that the 4 most significant bits do not belong to the entry, and vice versa, if it is odd
	;#############################################################################################
	mov ax, [file_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx

	mov si, ROOTDIR_AND_FAT_OFFSET
	add si, ax
	lodsw

	or dx, dx
	jz even

odd:
	shr ax, 4
	jmp nextClusterTest
even:
	and ax, 0x0fff

nextClusterTest:
	cmp ax, 0x0ff8
	jae end_load_file

	mov [file_cluster], ax
	jmp file_cluster_loop

end_load_file:
	pop cx
	pop bx
	pop ax
	pop es
	pop di
	pop si
	ret

;=========================================
;read a given number of sector on the disk
;input: 
;	- LBA index in ax
;	- number of sector to read in bx
;	- memory segment in es
;	- memory offset in di
;output: es:di
;=========================================
disk_read:
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	call lba2chs

	mov al, bl
	mov dl, 0x0
	mov bx, di
	mov di, 3 ;counter

retry_disk:
	stc
	mov ah, 0x2
	int 0x13

	jnc done_read
	call disk_reset

	dec di
	or di, di
	jnz retry_disk

failDiskRead:
	mov si, read_failure
	call print
	hlt
	jmp halt

disk_reset:
	pusha

	mov ah, 0x0
	stc
	int 13h
	jc failDiskRead

	popa
	ret

done_read:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret


;=========================================
;convert a logical block address to 
;cylinder head sector address
;input: 
;	- LBA index in ax
;output:
;	- cx [bits 0-5]: sector number
;	- cx [bits 6-15]: cylinder
;	- dh: head 
;=========================================
lba2chs:
	push ax

	xor dx, dx
	div word [bpb_sectors_per_track]
	inc dx
	mov cl, dl ;sector

	xor dx, dx
	div word [bpb_heads]
	mov ch, al
	shl ah, 6
	or cl, ah ;cylinder

	shl dx, 8 ;in dh: head

	pop ax
	ret

;===============================================
; This function prints a whole string, where the 
; input string is stored in the register "SI"
;===============================================
print_boot_screen:
	mov ah, 0x3 ;get cursor position
	mov bh, 0
	int 0x10

	mov dl, 37

	mov ah, 0x2 ;set cursor position
	mov bh, 0
	int 0x10

print:
	push ax
	push bx
	push si
	xor ax, ax
	mov ah, 0xe

print_loop:
	lodsb ;load a single byte from si to al
	or al, al
	jz done_print
	xor bx, bx
	int 0x10
	jmp print_loop

done_print:
	pop si
	pop bx
	pop ax
	ret

msg DB 10, 10, "NOVIX", 13, 10, 0
read_failure DB "failed t read disk !", 13, 10, 0
file_name DB "KERNEL  BIN"
file_cluster DW 0
msg_file_not_found DB "this file doesn't exist !", 13, 10, 0
ROOTDIR_AND_FAT_OFFSET EQU 0xc000
KERNEL_SEGMENT EQU 0x2000
times 510-($-$$) db 0x90
dw 0xaa55