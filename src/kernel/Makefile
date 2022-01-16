BUILD_DIR?=build/
ASM?=nasm
CC16?=/usr/bin/watcom/binl/wcc
LD16?=/usr/bin/watcom/binl/wlink

.PHONY: all kernel clean

all: kernel

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin:
	$(ASM) main.asm -f bin -o $(BUILD_DIR)/kernel.bin

clean:
	rm -f $(BUILD_DIR)/kernel.bin