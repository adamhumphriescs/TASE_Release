export BUILD_DIR?=/TASE_BUILD
export RUN_DIR?=/TASE

# all headers
export INCLUDE_DIR=$(RUN_DIR)/include

export TASE_CLANG=$(RUN_DIR)/bin/clang
export CLANG=$(RUN_DIR)/llvm-3.4.2/bin/clang

# TASE headers + .c/S files
TASE_DIR=$(BUILD_DIR)/tase
export TASE_LINK=$(RUN_DIR)/tase_link.ld

# options for TASE compilation
export MODELED_FN_ARG=-mllvm -x86-tase-modeled-functions=$(INCLUDE_DIR)/tase/core_modeled.h
export NO_FLOAT_ARG=-mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx

INCLUDES=$(addprefix $(INCLUDE_DIR)/tase/,$(notdir $(wildcard $(BUILD_DIR)/tase/include/*.h)))

LIBTASEC_PATH=$(BUILD_DIR)/test/libc
MUSL_PATH=$(BUILD_DIR)/musl

# required libs from musl
STDLIBS=abs atof atoi atol atoll bsearch div ecvt fcvt gcvt imaxabs imaxdiv labs ldiv llabs lldiv qsort
NETLIBS=htonl htons ntohl ntohs

MUSL_OBJS=$(addprefix $(MUSL_PATH)/obj/src/,string/*.o locale/__lctrans.o ctype/*.o errno/*.o $(addsuffix .o, $(addprefix stdlib/, $(STDLIBS))) errno/*.o $(addsuffix .o,$(addprefix network/,$(NETLIB))) math/*.o fenv/fenv.o fenv/fesetround.o)
#stdio/*.o

# dummy project vars
CKSUM_OBJS=$(addsuffix .o,$(basename $(wildcard $(BUILD_DIR)/microbenchmarks/concrete/cksum/*.c)))

export LLVM_LIBS=$(addprefix $(RUN_DIR)/llvm-3.4.2/lib/,libLLVMInstrumentation.a libLLVMIRReader.a libLLVMAsmParser.a libLLVMOption.a libLLVMLTO.a libLLVMLinker.a libLLVMipo.a libLLVMVectorize.a libLLVMTableGen.a libLLVMX86Disassembler.a libLLVMX86AsmParser.a libLLVMX86CodeGen.a libLLVMSelectionDAG.a libLLVMAsmPrinter.a libLLVMMCDisassembler.a libLLVMMCParser.a libLLVMX86Desc.a libLLVMX86Info.a libLLVMX86AsmPrinter.a libLLVMX86Utils.a libLLVMInterpreter.a libLLVMMCJIT.a libLLVMRuntimeDyld.a libLLVMExecutionEngine.a libLLVMCodeGen.a libLLVMObjCARCOpts.a libLLVMScalarOpts.a libLLVMInstCombine.a libLLVMTransformUtils.a libLLVMAnalysis.a libLLVMTarget.a libLLVMMC.a libLLVMObject.a libLLVMBitWriter.a libLLVMBitReader.a libLLVMCore.a libLLVMSupport.a libLLVMJIT.a libLTO.a libLLVMipa.a)

# minisat cmake
MINISAT_OPTS=-DSTATIC_BINARIES=ON -DCMAKE_INSTALL_PREFIX="$(RUN_DIR)"

# STP cmake
STP_OPTS=-DBUILD_SHARED_LIBS:BOOL=OFF -DENABLE_PYTHON_INTERFACE:BOOL=OFF -DCMAKE_INSTALL_PREFIX="$(RUN_DIR)" -DUSE_CRYPTOMINISAT4:BOOL=OFF -DNO_BOOST:BOOL=ON

# tsx_llvm cmake
TSX_LLVM_OPTS=-DCMAKE_INSTALL_PREFIX="$(RUN_DIR)" -DCMAKE_BUILD_TYPE="Debug" -DCMAKE_C_FLAGS="-fdiagnostics-color=always -fmax-errors=3" -DCMAKE_CXX_FLAGS="-fdiagnostics-color=always -fmax-errors=3" -DLLVM_USE_LINKER="gold" -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_PROJECTS="clang" -DBUILD_SHARED_LIBS=FALSE -DLLVM_OPTIMIZED_TABLEGEN=TRUE -DLLVM_INCLUDE_EXAMPLES=FALSE -DLLVM_INCLUDE_TESTS=FALSE -DLLVM_INCLUDE_GO_TESTS=FALSE -DLLVM_INCLUDE_BENCHMARKS=FALSE -DLLVM_INCLUDE_DOCS=FALSE -DLLVM_ENABLE_OCAMLDOC=FALSE -DLLVM_ENABLE_BINDINGS=FALSE -DLLVM_INCLUDE_UTILS=FALSE -DLLVM_INCLUDE_RUNTIMES=FALSE -DLLVM_BUILD_STATIC=FALSE -DTASE_INCLUDE_DIR="$(INCLUDE_DIR)"


# openssl cmake
#SSL_OPTS=--prefix="$(RUN_DIR)" --openssldir="$(RUN_DIR)" -DPURIFY -DCLIVER -DTASE_TSX $(MODELED_FN_ARG) -I$(INCLUDE_DIR)/tase/ -T$(TASE_LINK) $(NO_FLOAT_ARG) -mllvm -verify-regalloc -mllvm -verify-machineinstrs -mllvm -x86-tase-paranoid-control-flow=true -O1 -Qunused-arguments no-asm no-engine no-err no-gmp no-hw no-hardware no-locking no-shared no-threads no-zlib no-cast no-comp no-dso no-dtls no-dtls1 no-md4 no-mdc2 no-nextprotoneg no-npn no-psk no-ripemd no-srtp no-ssl2 no-weak-ssl-ciphers


KLEE_LIBS=kleeTase kleeSupport kleeModule kleeCore kleeBasic kleaverSolver kleaverExpr
export KLEE_LINK_LIBS=$(addprefix $(RUN_DIR)/lib/,$KLEE_LIBS libtase.a libminisat.a libstp.a)
export KLEE_BITCODE=$(addprefix $(RUN_DIR)/install/klee_bitcode/,klee-libc.bc kleeRuntimeIntrinsic.bc)

# for cleanup - we don't need these tools in the container but they are built with TASE_CLANG
BIN_RM=bugpoint c-index-test clang-check clang-extdef-mapping clang-format clang-import-test clang-offload-bundler clang-refactor clang-rename diagtool dsymutil git-clang-format hmaptool llc lli llvm-ar llvm-as llvm-bcanalyzer llvm-c-test llvm-cat llvm-cfi-verify llvm-config llvm-cov llvm-cvtres llvm-cxxdump llvm-cxxfilt llvm-cxxmap llvm-diff llvm-dis llvm-dlltool llvm-dwarfdump llvm-dwp llvm-elfabi llvm-exegesis llvm-extract llvm-lib llvm-link llvm-lto llvm-lto2 llvm-mc llvm-mca llvm-modextract llvm-mt llvm-nm llvm-objcopy llvm-objdump llvm-opt-report llvm-pdbutil llvm-profdata llvm-ranlib llvm-rc llvm-readelf llvm-readobj llvm-rtdyld llvm-size llvm-split llvm-stress llvm-strings llvm-strip llvm-symbolizer llvm-tblgen llvm-undname llvm-xray minisat minisat_core obj2yaml opt sancov sanstats scan-build scan-view stp_simple verify-uselistorder yaml2obj

.PHONY: tase_clang
tase_clang: $(TASE_CLANG) parseltongue


$(TASE_CLANG): $(INCLUDES)
	mkdir -p $(BUILD_DIR)/build/llvm/
	cd $(BUILD_DIR)/build/llvm/ && cmake $(TSX_LLVM_OPTS) $(BUILD_DIR)/llvm
	$(MAKE) -C $(BUILD_DIR)/build/llvm/
	$(MAKE) -C $(BUILD_DIR)/build/llvm/ install


$(INCLUDE_DIR)/tase/%.h: $(BUILD_DIR)/tase/include/%.h
	cp $< $@ 


.PHONY: parseltongue
	cp -r $(BUILD_DIR)/parseltongue86/ $(RUN_DIR)/parseltongue86/
	cd $(RUN_DIR)/parseltongue86/ && ./setup.sh


.PHONY: setup
setup: klee cleanup


klee: $(RUN_DIR)/lib/libtase.a $(RUN_DIR)/lib/musl.o $(BUILD_DIR)/build/klee/lib/checksum.a $(RUN_DIR)/lib/libstp.a $(RUN_DIR)/lib/libminisat.a
	mkdir -p $(BUILD_DIR)/build/klee
	$(MAKE) -C $(BUILD_DIR)/klee/


/objdump:
	cp $(BUILD_DIR)/objdump/objdump.c $(BUILD_DIR)/binutils-gdb/binutils/
	cp $(BUILD_DIR)/objdump/section.c $(BUILD_DIR)/objdump/bfd.h $(BUILD_DIR)/binutils-gdb/bfd/
	cd $(BUILD_DIR)/binutils-gdb && ./configure
	$(MAKE) -C $(BUILD_DIR)/binutils-gdb/
	cp $(BUILD_DIR)/binutils-gdb/binutils/objdump /objdump


$(RUN_DIR)/lib/libtase.a: $(TASE_CLANG)
	mkdir -p $(BUILD_DIR)/build/tase
	$(MAKE) -C $(BUILD_DIR)/tase


# ar -> ld because otherwise get multiple definition errors from errno
$(RUN_DIR)/lib/musl.o: $(TASE_CLANG)
	cp $(MUSL_PATH)/TASEConfig/config.mak_no_simd $(MUSL_PATH)/config.mak
	env PATH="$(RUN_DIR)/bin:$${PATH}" $(MAKE) -C $(MUSL_PATH)
	ar crs libtasec.a $(MUSL_OBJS)
	mkdir -p ltbuild lib
	cd ltbuild && ar -x ../libtasec.a && ld -o $(RUN_DIR)/lib/musl.o -r *.o
	rm -rf ltbuild
	rm libtasec.a


$(BUILD_DIR)/build/klee/lib/checksum.a: $(CKSUM_OBJS)
	mkdir -p $(BUILD_DIR)/build/klee/lib/
	ar crs $(BUILD_DIR)/build/klee/lib/checksum.a $(CKSUM_OBJS)


$(BUILD_DIR)/microbenchmarks/concrete/cksum/%.o: $(BUILD_DIR)/microbenchmarks/concrete/cksum/%.c $(TASE_CLANG)
	$(TASE_CLANG) -fPIC -I$(BUILD_DIR)/microbenchmarks/concrete/cksum/ -I$(INCLUDE_DIR)/tase/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


$(RUN_DIR)/lib/libstp.a: $(RUN_DIR)/lib/libminisat.a
	mkdir -p $(BUILD_DIR)/build/stp
	cd $(BUILD_DIR)/build/stp && cmake $(STP_OPTS) $(BUILD_DIR)/stp
	$(MAKE) -C $(BUILD_DIR)/build/stp/
	$(MAKE) -C $(BUILD_DIR)/build/stp/ install


$(RUN_DIR)/lib/libminisat.a:
	mkdir -p $(BUILD_DIR)/build/minisat/
	cd $(BUILD_DIR)/build/minisat/ && cmake $(MINISAT_OPTS) $(BUILD_DIR)/minisat
	$(MAKE) -C $(BUILD_DIR)/build/minisat/
	$(MAKE) -C $(BUILD_DIR)/build/minisat/ install


.PHONY: cleanup
cleanup: klee $(TASE_CLANG)
	rm -f $(RUN_DIR)/lib/libLL*.a $(RUN_DIR)/lib/libclang* $(RUN_DIR)/lib/*.so* $(RUN_DIR)/bin/ll* $(RUN_DIR)/bin/minisat* $(RUN_DIR)/bin/s* $(addprefix $(RUN_DIR)/bin/,$(BIN_RM))


#.PHONY: openssl
#openssl:
#	cd openssl && ./config $(SSL_OPTS)
#	$(MAKE) -C $(BUILD_DIR)/openssl/ build_taseall
