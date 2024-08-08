.POSIX:
NAME         = ledmat
DEVICE       = atmega328p
PORT         = /dev/ttyACM0
BAUD         = 115200
CFLAGS.a     = $(CFLAGS)
XCFLAGS.a    = $(CFLAGS) -Os -DF_CPU=16000000UL -mmcu=$(DEVICE)
LDLIBS.a     = $(LDLIBS)
LDLIBS       =
EXEC         = ./
XCC          = avr-gcc
JSIMPL       = node



.SUFFIXES:
.SUFFIXES: .c .xo .o .to .ea .bin .elf .hex

.c.xo:
	$(XCC) $(XCFLAG.a)       -o $@ -c $<

.c.o:
	$(CC) $(CFLAGS.a)        -o $@ -c $<

.c.to:
	$(CC) $(CFLAGS.a) -DTEST -o $@ -c $<

.ea.bin:
	$(CC) $(LDFLAGS.a) -o $@ $< $(LDLIBS.a)

.elf.hex:
	avr-objcopy -j .text -j .data -O ihex $< $@



all:
include deps.mk

sources.xo  = $(sources.c:.c=.xo)
sources.o   = $(sources.c:.c=.o)
sources.to  = $(sources.c:.c=.to)
sources.ea  = $(sources.c:.c=.ea)
sources.bin = $(sources.c:.c=.bin)


derived-assets = \
	$(NAME).hex    \
	$(NAME).elf    \
	$(sources.xo)  \
	$(sources.o)   \
	$(sources.to)  \
	$(sources.ea)  \
	$(sources.bin) \



## Default target.  Builds all artifacts required for testing
## and installation.
all: $(derived-assets)


$(sources.xo) $(sources.o) $(sources.to): Makefile

$(sources.ea):
	$(AR) $(ARFLAGS) $@ $?

$(NAME).elf: $(sources.xo)
	$(XCC) $(LDFLAGS) -o $@ $(sources.xo)
	avr-size $@



.SUFFIXES: .mjs-run
tests.mjs-run = $(tests.mjs:.mjs=.mjs-run)
$(tests.mjs-run):
	$(JSIMPL) $*.mjs

check-node: $(tests.mjs-run)


.SUFFIXES: .bin-check
sources.bin-check = $(sources.c:.c=.bin-check)
$(sources.bin-check):
	$(EXEC)$*.bin

check-c: $(sources.bin-check)


check-t: check-node check-c


.SUFFIXES: .clang-format .clang-tidy .c-lint
lints = \
	$(sources.c:.c=.clang-format) \
	$(sources.c:.c=.clang-tidy)   \
	$(sources.c:.c=.c-lint)       \

$(lints):
	sh tests/"`echo "$@" | cut -d. -f2`".sh $*.c

check-lint: $(lints)


check-integration:


tests/assert-clean.sh: all
assert-tests = \
	tests/assert-deps.sh  \
	tests/assert-clean.sh \

$(assert-tests): ALWAYS
	+sh $@

check-asserts: $(assert-tests)


## Run all tests.  Each test suite is isolated, so that a parallel
## build can run tests at the same time.  The required artifacts
## are created if missing.
check: check-t check-lint check-integration check-asserts



## Remove *all* derived artifacts produced during the build.
## A dedicated test asserts that this is always true.
clean:
	rm -rf \
		$(derived-assets)

## Flash the binary to the $(DEVICE) available at $(PORT).
deploy: $(NAME).hex
	avrdude \
		-p $(DEVICE) \
		-c arduino   \
		-P $(PORT)   \
		-b $(BAUD)   \
		-U flash:w:$(NAME).hex:i


MAKEFILE = Makefile
## Show this help.
help:
	cat $(MAKEFILE) | sh tools/makehelp.sh


ALWAYS:
