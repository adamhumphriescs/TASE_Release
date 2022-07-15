CC=/TASE/bin/clang
RUN_DIR=/TASE/
OBJS=$(addprefix /project/build/,$(addsuffix .o,$(basename $(wildcard *.c))))
BIN?=main
ROOT?=/project
OUTDIR?=/project/build

all:
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make $(BIN)'

$(OUTDIR)/%.o: %.c
	mkdir -p $(OUTDIR)/bitcode/
	$(CC) -c -I$(INCLUDE_DIR)/tase/ -I$(INCLUDE_DIR)/traps/ -O1  $(MODELED_FN_ARG) $(NO_FLOAT_ARG) -mllvm -x86-tase-instrumentation-mode=naive $< -o $@
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
	/usr/bin/c++ -T/TASE/tase_link.ld -fno-pie -no-pie -D_GLIBCXX_USE_CXX11_ABI=0 -I/TASE/include/openssl/ -Wall -Wextra -Wno-unused-parameter -O0 -o $(OUTDIR)/$(BIN)  -rdynamic /TASE/lib/main.cpp.o build/everything.o -Wl,--start-group $$(find /TASE/lib/ -name '*.a') $(RUN_DIR)/llvm-3.4.2/lib/libLLVMInstrumentation.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMIRReader.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMAsmParser.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMOption.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMLTO.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMLinker.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMipo.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMVectorize.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMTableGen.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86Disassembler.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86AsmParser.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86CodeGen.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMSelectionDAG.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMAsmPrinter.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMMCDisassembler.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMMCParser.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86Desc.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86Info.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86AsmPrinter.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMX86Utils.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMInterpreter.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMMCJIT.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMRuntimeDyld.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMExecutionEngine.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMCodeGen.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMObjCARCOpts.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMScalarOpts.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMInstCombine.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMTransformUtils.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMAnalysis.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMTarget.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMMC.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMObject.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMBitWriter.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMBitReader.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMCore.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMSupport.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMJIT.a $(RUN_DIR)/llvm-3.4.2/lib/libLTO.a $(RUN_DIR)/llvm-3.4.2/lib/libLLVMipa.a -lz -lpthread -ltinfo -ldl -lm -lstdc++ -Wl,--end-group
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
