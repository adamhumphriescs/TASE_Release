TASE_ROOT_DIR=/TASE
OPTS=-mllvm -x86-tase-instrumentation-mode=none
TASE_CLANG=$(TASE_ROOT_DIR)/install_root/bin/clang

all: bitscan bitscan.interp.cpp

bitscan: clean
	$(TASE_CLANG) $(OPTS) -c bitscan.s
	$(TASE_CLANG) $(OPTS) test.c bitscan.o -o bitscan
	./bitscan

.PHONY: bitscan.interp.cpp
bitscan.interp.cpp:
	../test.py bitscan -f bitscan.tase ../../ > bitscan.interp.cpp

.PHONY: test
test:
	$(TASE_CLANG) $(OPTS) bitscan_test.c -o bitscan_test
