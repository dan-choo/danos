MAKEFLAGS+=-rR

# Replace with your cross compiler tools?
CC=x86_64-elf-gcc
LD=x86_64-elf-ld

KERNEL=danos.elf
IMAGE=danos.iso

CFLAGS += \
	-Iinclude/ \
    -Wall \
    -Wextra \
    -std=gnu11 \
    -ffreestanding \
    -fno-stack-protector \
    -fno-stack-check \
    -fno-lto \
    -fno-PIE \
    -fno-PIC \
    -m64 \
    -march=x86-64 \
    -mabi=sysv \
    -mno-80387 \
    -mno-mmx \
    -mno-sse \
    -mno-sse2 \
    -mno-red-zone \
    -mcmodel=kernel

CPPFLAGS := \
    -I. \
    $(CPPFLAGS) \
    -MMD \
    -MP

LDFLAGS += \
    -nostdlib \
    -static \
    -m elf_x86_64 \
    -z max-page-size=0x1000 \
    -T boot/linker.ld

BUILD_DIR=build
CFILES=$(shell find -L ./kernel -type f -name '*.c')
OBJS=$(CFILES:.c=.o)
BUILD_OBJS=$(patsubst ./%.c, build/%.o, $(CFILES))

all: image

run: $(IMAGE)
	qemu-system-x86_64 -M q35 -m 2G -cdrom $(IMAGE) -boot d

$(IMAGE): $(KERNEL)
	mkdir -p iso_root
	make -C boot/limine
	cp -v danos.elf boot/limine.cfg boot/limine/limine.sys \
	boot/limine/limine-cd.bin boot/limine/limine-cd-efi.bin iso_root/
	xorriso -as mkisofs -b limine-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --efi-boot limine-cd-efi.bin \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        iso_root -o $(IMAGE)
	./boot/limine/limine-deploy $(IMAGE)

kernel: $(KERNEL)

$(KERNEL): $(BUILD_OBJS)
	$(LD) $(BUILD_OBJS) $(LDFLAGS) -o $@

$(BUILD_DIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -rf build iso_root danos.elf danos.iso

.PHONY: clean run kernel


