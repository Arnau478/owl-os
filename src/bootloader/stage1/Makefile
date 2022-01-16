BUILD_DIR?=build/
ASM?=nasm
CC16?=/usr/bin/watcom/binl/wcc
LD16?=/usr/bin/watcom/binl/wlink

.PHONY: all stage1 clean

all: stage1

stage1: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin:
	$(ASM) boot.asm -f bin -o $(BUILD_DIR)/stage1.bin

clean:
	rm -f $(BUILD_DIR)/stage1.bin