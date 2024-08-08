sources.c = \
	src/processor.c \

sources.mjs = \
	src/main.mjs \
	src/processor.mjs \
	src/worklet.mjs \

tests.mjs = \
	tests/js/processor.mjs \

src/processor.o	src/processor.lo	src/processor.to:	src/processor.h

src/processor.ea:	src/processor.to

src/processor.bin-check:	src/processor.bin


src/processor.o	src/processor.lo	src/processor.to:

src/processor.ea:

tests/js/processor.mjs-t: tests/js/processor.mjs
