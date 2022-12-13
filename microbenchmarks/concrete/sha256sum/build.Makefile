include /TASE/install/exports.Makefile

BIN?=main
ROOT?=/project
OUTDIR?=/project/build

OBJS=$(addprefix $(OUTDIR)/,$(addsuffix .o,$(basename $(wildcard *.c))))
TASE=$(addprefix $(OUTDIR)/,$(addsuffix .tase,$(basename $(wildcard *.c))))
VARS=$(addprefix $(OUTDIR)/,$(addsuffix .vars,$(basename $(wildcard *.c))))


all: $(OUTDIR)/$(BIN) finish

$(OUTDIR)/%.o: %.c
	$(TASE_CLANG) $(TASE_CFLAGS) $< -o $@
	objcopy --localize-hidden $@

$(OUTDIR)/%.tase: $(OUTDIR)/%.o
	nm --defined-only $< | grep -i " t " | cut -d' ' -f 3 >> $@

$(OUTDIR)/%.vars: $(OUTDIR)/%.o $(OUTDIR)/$(BIN)
	python3 /TASE/parseltongue86/rosettastone.py $(OUTDIR)/$(BIN) -f $< > $@

$(OUTDIR)/everything.o: $(OBJS)
	ld -r $(OBJS) /TASE/lib/musl.o -o $(OUTDIR)/everything.o
	cd /TASE/install/ && ./localize.sh $(OUTDIR)/everything.o

$(OUTDIR)/$(BIN).tase: $(TASE)
	cat $(TASE) /TASE/install/libtasec.syms > $(OUTDIR)/tmp.tase
	echo "begin_target_inner" >> $(OUTDIR)/tmp.tase
	sort $(OUTDIR)/tmp.tase | uniq > $(OUTDIR)/$(BIN).tase && rm $(OUTDIR)/tmp.tase

$(OUTDIR)/$(BIN).vars: $(VARS) $(OUTDIR)/$(BIN)
	readelf --relocs $(OUTDIR)/$(BIN)| grep GLOB_DAT | awk '{print $$1, "0x8"; print $$4, "0x10"}' > vars.tmp
	cat $(VARS) vars.tmp | sort | uniq > $(OUTDIR)/$(BIN).vars
	rm vars.tmp

$(OUTDIR)/$(BIN): $(OUTDIR)/everything.o
	/usr/bin/c++ -T/TASE/tase_link.ld -fno-pie -no-pie -D_GLIBCXX_USE_CXX11_ABI=0 -I/TASE/include/openssl/ -Wall -Wextra -Wno-unused-parameter -O0 -o $(OUTDIR)/$(BIN)  -rdynamic /TASE/lib/main.cpp.o $(OUTDIR)/everything.o -Wl,--start-group $(LLVM_LIBS) $(KLEE_LINK_LIBS) -lz -lpthread -ltinfo -ldl -lm -lstdc++ -Wl,--end-group

.PHONY: finish
finish: $(OUTDIR)/$(BIN) $(OUTDIR)/$(BIN).tase $(OUTDIR)/$(BIN).vars
	mkdir -p $(OUTDIR)/bitcode/ && rm -rf $(OUTDIR)/bitcode/*
	echo '#!/bin/bash' > $(OUTDIR)/run.sh
	echo 'KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ ./$(BIN) -project=$(BIN) $${@}' >> $(OUTDIR)/run.sh
	chmod +x $(OUTDIR)/run.sh
	cd $(OUTDIR)/ && ./run.sh -tasePreProcess=TRUE
	cp /TASE/install/compile.sh $(OUTDIR)/
	cp /TASE/install/klee_bitcode/* $(OUTDIR)/bitcode/
	cd $(ROOT) && python3 /TASE/parseltongue86/parseltongue86.py -n -f $(OUTDIR)/$(BIN).tase $(OUTDIR)/$(BIN) /TASE/include/tase/ $(BIN) -t 40 
	cd $(OUTDIR) && ls bitcode/ | grep .cpp$ | xargs -n1 -P20 -I{} ./compile.sh bitcode/{}

	if [ $$(find $(OUTDIR)/bitcode/ -name '$(BIN).interp.*.bc' | wc -l) -gt 1 ]; \
	then\
		/TASE/llvm-3.4.2/bin/llvm-link $$(find $(OUTDIR)/bitcode/ -name '$(BIN).interp.*.bc') -o $(OUTDIR)/bitcode/$(BIN).interp.bc;\
	else\
		mv $(OUTDIR)/bitcode/$(BIN).interp.0.bc $(OUTDIR)/bitcode/$(BIN).interp.bc;\
	fi
