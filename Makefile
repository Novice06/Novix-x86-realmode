
ASM = nasm
CC16 = /usr/bin/watcom/binl/wcc
CFLAGS16 = -s -wx -ms -zl -zq
LD16 = /usr/bin/watcom/binl/wlink
ASM_FLAGS = -f obj
SRC_DIR = src
BUILD_DIR = build

#
# Floppy image
#

floppy_image: always $(BUILD_DIR)/main.img

$(BUILD_DIR)/main.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=2880
	mkfs.fat -F 12 -n "VICEOS" $(BUILD_DIR)/main.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

#
# Bootloader
#

bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: $(SRC_DIR)/bootloader/boot.asm
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#
# Kernel
#

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: $(SRC_DIR)/kernel/main.asm
	$(ASM) $(SRC_DIR)/kernel/main.asm $(ASM_FLAGS) -o $(BUILD_DIR)/kernel/asm/main.obj
	$(ASM) $(SRC_DIR)/kernel/stdio/stdio.asm $(ASM_FLAGS) -o $(BUILD_DIR)/kernel/asm/stdio.obj
	$(CC16) $(CFLAGS16) -fo=$(BUILD_DIR)/kernel/c/main.obj $(SRC_DIR)/kernel/main.c
	$(CC16) $(CFLAGS16) -fo=$(BUILD_DIR)/kernel/c/stdio.obj $(SRC_DIR)/kernel/stdio/stdio.c
	$(LD16) NAME $(BUILD_DIR)/kernel.bin FILE \{$(BUILD_DIR)/kernel/asm/main.obj $(BUILD_DIR)/kernel/asm/stdio.obj $(BUILD_DIR)/kernel/c/main.obj $(BUILD_DIR)/kernel/c/stdio.obj \} OPTION MAP=$(BUILD_DIR)/kernel.map @$(SRC_DIR)/kernel/linker.lnk

always:
	mkdir build/kernel
	mkdir build/kernel/asm
	mkdir build/kernel/c
clean:
	rm -rf build/*