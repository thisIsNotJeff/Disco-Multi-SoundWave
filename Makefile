H=$(or $(HOME),$(USERPROFILE),/ask/a/tutor/for/help)
COMP2300 ?= $(H)/.comp2300

ARM_PREFIX=$(COMP2300)/arm-none-eabi/bin/arm-none-eabi-

CC=$(ARM_PREFIX)gcc
LD=$(ARM_PREFIX)ld
OBJCOPY=$(ARM_PREFIX)objcopy

OPENOCD=$(COMP2300)/openocd/bin/openocd

SRCS := $(shell find src lib -name '*.c' -or -name '*.S')
OBJS := $(addsuffix .o,$(basename $(SRCS)))

CFLAGS ?=-nostdlib -nostartfiles -mcpu=cortex-m4 -mthumb -Wall -Werror -g
LDFLAGS ?=-nostdlib -nostartfiles -T lib/link.ld --print-memory-usage

TARGET ?= program.elf

all: $(TARGET)

.PHONY: check_home
check_home:
	echo hello $(H)

	ifndef H
		$(error something is not good)
	endif

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

%.o: %.S
	$(CC) $(CFLAGS) -o $@ -c $<

.PHONY: upload
upload: $(TARGET)
	$(OBJCOPY) -O binary $(TARGET) program.bin

	$(OPENOCD) -f board/stm32l4discovery.cfg -c "program program.elf verify reset exit"

clean:
	rm $(TARGET) $(OBJS) >/dev/null 2>/dev/null || true
