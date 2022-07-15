include /TASE/install/exports.Makefile

OBJS=$(addprefix /project/build/,$(addsuffix .o,$(basename $(wildcard *.c))))
BIN?=main
ROOT?=/project
OUTDIR?=/project/build


$(OUTDIR)/%.o: %.c
	mkdir -p $(OUTDIR)/bitcode/
	$(TASE_CLANG) -c -I$(INCLUDE_DIR)/tase/ -I$(INCLUDE_DIR)/traps/ -O1  $(MODELED_FN_ARG) $(NO_FLOAT_ARG) -mllvm -x86-tase-instrumentation-mode=naive $< -o $@
	objcopy --localize-hidden $@
	python3 /TASE/parseltongue86/rosettastone.py $(BIN) -f $@ >> $(OUTDIR)/tmp.vars
	cp /TASE/install/libtasec.syms $(OUTDIR)/tmp.tase
	nm --defined-only $@ | grep -i " t " | cut -d' ' -f 3 >> $(OUTDIR)/tmp.tase
	echo "begin_target_inner" >> $(OUTDIR)/tmp.tase
	sort $(OUTDIR)/tmp.vars | uniq > $(OUTDIR)/$(BIN).vars && rm $(OUTDIR)/tmp.vars
	sort $(OUTDIR)/tmp.tase | uniq > $(OUTDIR)/$(BIN).tase && rm $(OUTDIR)/tmp.tase

$(OUTDIR)/everything.o: $(OBJS)
	ld -r $(OBJS) /TASE/lib/musl.o -o $(OUTDIR)/everything.o
	cd /TASE/install/ && ./localize.sh $(OUTDIR)/everything.o

$(BIN): $(OUTDIR)/everything.o
	/usr/bin/c++ -T/TASE/tase_link.ld -fno-pie -no-pie -D_GLIBCXX_USE_CXX11_ABI=0 -I/TASE/include/openssl/ -Wall -Wextra -Wno-unused-parameter -O0 -o $(OUTDIR)/$(BIN)  -rdynamic /TASE/lib/main.cpp.o build/everything.o -Wl,--start-group $$(find /TASE/lib/ -name '*.a') $(LLVM_LIBS) $(KLEE_LINK_LIBS) -lz -lpthread -ltinfo -ldl -lm -lstdc++ -Wl,--end-group
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
