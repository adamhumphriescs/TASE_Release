BUILD_DIR=/TASE_BUILD
RUN_DIR=/TASE

# all headers
INCLUDE_DIR=$(RUN_DIR)/include

TASE_CLANG=$(RUN_DIR)/bin/clang
CLANG=$(RUN_DIR)/llvm-3.4.2/bin/clang

# TASE headers + .c/S files
TASE_DIR=$(BUILD_DIR)/test/tase
TASE_LINK=$(RUN_DIR)/tase_link.ld

# options for TASE compilation
MODELED_FN_ARG=-mllvm -x86-tase-modeled-functions=$(INCLUDE_DIR)/tase/core_modeled.h
NO_FLOAT_ARG=-mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx

LIBTASEC_PATH=$(BUILD_DIR)/test/libc
MUSL_PATH=$(BUILD_DIR)/musl

# required libs from musl
STDLIBS=abs atof atoi atol atoll bsearch div ecvt fcvt gcvt imaxabs imaxdiv labs ldiv llabs lldiv qsort
NETLIBS=htonl htons ntohl ntohs

MUSL_OBJS=$(MUSL_PATH)/obj/src/string/*.o $(MUSL_PATH)/obj/src/locale/__lctrans.o $(MUSL_PATH)/obj/src/ctype/*.o $(MUSL_PATH)/obj/src/errno/*.o $(addsuffix .o,$(addprefix $(MUSL_PATH)/obj/src/stdlib/,$(STDLIBS))) $(MUSL_PATH)/obj/src/errno/*.o $(addsuffix .o,$(addprefix $(MUSL_PATH)/obj/src/network/,$(NETLIB))) $(MUSL_PATH)/obj/src/math/*.o $(MUSL_PATH)/obj/src/fenv/fenv.o $(MUSL_PATH)/obj/src/fenv/fesetround.o


# soft float
SFLOAT_DIR=$(BUILD_DIR)/compiler-rt_soft_float
SFLOAT_OBJS=$(addsuffix .o,$(basename $(wildcard $(SFLOAT_DIR)/*.c)))

# tase Objects
TASE_OBJSA=$(addprefix $(TASE_DIR)/,modeled/exit_tase.o)
TASE_OBJSB=$(addprefix $(TASE_DIR)/,log.o common.o make_byte_symbolic.o)
TASE_OBJSC=$(addprefix $(TASE_DIR)/,springboard.o)
TASE_SHIMOBJS=$(addprefix $(TASE_DIR)/traps/,tase_shims.o mem_traps.o)
TASE_OBJS=$(TASE_OBJSA) $(TASE_OBJSC) $(TASE_OBJSB) $(TASE_SHIMOBJS) $(SFLOAT_OBJS)


# dummy project vars
CKSUM_OBJS=$(addsuffix .o,$(basename $(wildcard $(BUILD_DIR)/test/microbenchmarks/concrete/cksum/*.c)))


# minisat cmake
MINISAT_OPTS=-DSTATIC_BINARIES=ON -DCMAKE_INSTALL_PREFIX="$(RUN_DIR)"

# STP cmake
STP_OPTS=-DBUILD_SHARED_LIBS:BOOL=OFF -DENABLE_PYTHON_INTERFACE:BOOL=OFF -DCMAKE_INSTALL_PREFIX="$(RUN_DIR)" -DUSE_CRYPTOMINISAT4:BOOL=OFF -DNO_BOOST:BOOL=ON


# tsx_llvm cmake
TSX_LLVM_OPTS=-DCMAKE_INSTALL_PREFIX="$(RUN_DIR)" -DCMAKE_BUILD_TYPE="Debug" -DCMAKE_C_FLAGS="-fdiagnostics-color=always -fmax-errors=3" -DCMAKE_CXX_FLAGS="-fdiagnostics-color=always -fmax-errors=3" -DLLVM_USE_LINKER="gold" -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_PROJECTS="clang" -DBUILD_SHARED_LIBS=FALSE -DLLVM_OPTIMIZED_TABLEGEN=TRUE -DLLVM_INCLUDE_EXAMPLES=FALSE -DLLVM_INCLUDE_TESTS=FALSE -DLLVM_INCLUDE_GO_TESTS=FALSE -DLLVM_INCLUDE_BENCHMARKS=FALSE -DLLVM_INCLUDE_DOCS=FALSE -DLLVM_ENABLE_OCAMLDOC=FALSE #-DLLVM_ENABLE_BINDINGS=FALSE -DLLVM_INCLUDE_UTILS=FALSE -DLLVM_BUILD_STATIC=TRUE

#  -DLLVM_INCLUDE_TOOLS=FALSE <- do individual tool disable later
#later add -DLLVM_DYLIB_COMPONENTS -> list of components to include


# openssl cmake
SSL_OPTS=--prefix="$(RUN_DIR)" --openssldir="$(RUN_DIR)" -DPURIFY -DCLIVER -DTASE_TSX -mllvm -x86-tase-modeled-functions=$(INC_DIR)/tase/core_modeled.h -I$(INC_DIR)/tase/ -T$(RUN_DIR)/tase_link.ld -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx -mllvm -verify-regalloc -mllvm -verify-machineinstrs -mllvm -x86-tase-paranoid-control-flow=true -O1 -Qunused-arguments no-asm no-engine no-err no-gmp no-hw no-hardware no-locking no-shared no-threads no-zlib no-cast no-comp no-dso no-dtls no-dtls1 no-md4 no-mdc2 no-nextprotoneg no-npn no-psk no-ripemd no-srtp no-ssl2 no-weak-ssl-ciphers



# Klee CMAKE variables
KLEE_BUILD_TYPE=Release+Debug+Asserts

KLEE_ENV=CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 -fno-pie -no-pie -T$(RUN_DIR)/tase_link.ld -I$(INCLUDE_DIR)/openssl/"

KLEE_OPTS=-DCMAKE_INSTALL_PREFIX="$(RUN_DIR)" -DLLVM_CONFIG_BINARY="$(RUN_DIR)/llvm-3.4.2/bin/llvm-config" -DLLVMCC="$(CLANG)" -DLLVMCXX="$(CLANG)++" -DENABLE_KLEE_UCLIBC=FALSE -DENABLE_POSIX_RUNTIME=FALSE -DENABLE_SOLVER_STP=TRUE -DSTP_DIR="$(BUILD_DIR)/build_stp" -DCMAKE_BUILD_TYPE=Release -DENABLE_KLEE_ASSERTS=FALSE -DENABLE_UNIT_TESTS=FALSE -DENABLE_SYSTEM_TESTS=FALSE -DENABLE_DOCS=FALSE -DLLVM_INCLUDE_DIRS="$(RUN_DIR)/include/llvm-3.4.2/include/" -DLLVM_LIBRARY_DIRS="$(RUN_DIR)/include/llvm-3.4.2/lib/" -DKLEE_RUNTIME_BUILD_TYPE=$(KLEE_BUILD_TYPE)

KLEE_LIBS=kleeTase kleeSupport kleeModule kleeCore kleeBasic kleaverSolver kleaverExpr

LLVM_LIBS=clangTooling clangStaticAnalyzerFrontend clangStaticAnalyzerCore clangStaticAnalyzerCheckers clangSerialization clangSema clangRewriteFrontend clangRewriteCore clangParse clangLex clangIndex clangFrontendTool clangFrontend clangFormat clangEdit clangDynamicASTMatchers clangDriver clangCodeGen clangBasic clangAnalysis clangASTMatchers clangAST clangARCMigrate clang LTO LLVMipo LLVMipa LLVMXCoreInfo LLVMXCoreDisassembler LLVMXCoreDesc LLVMXCoreCodeGen LLVMXCoreAsmPrinter LLVMX86Utils LLVMX86Info LLVMX86Disassembler LLVMX86Desc LLVMX86CodeGen LLVMX86AsmPrinter LLVMX86AsmParser LLVMVectorize LLVMTransformUtils LLVMTarget LLVMTableGen LLVMSystemZInfo LLVMSystemZDisassembler LLVMSystemZDesc LLVMSystemZCodeGen LLVMSystemZAsmPrinter LLVMSystemZAsmParser LLVMSupport LLVMSparcInfo LLVMSparcDesc LLVMSparcCodeGen LLVMSelectionDAG LLVMScalarOpts LLVMRuntimeDyld LLVMR600Info LLVMR600Desc LLVMR600CodeGen LLVMR600AsmPrinter LLVMPowerPCInfo LLVMPowerPCDesc LLVMPowerPCCodeGen LLVMPowerPCAsmPrinter LLVMPowerPCAsmParser LLVMOption LLVMObject LLVMObjCARCOpts LLVMNVPTXInfo LLVMNVPTXDesc LLVMNVPTXCodeGen LLVMNVPTXAsmPrinter LLVMMipsInfo LLVMMipsDisassembler LLVMMipsDesc LLVMMipsCodeGen LLVMMipsAsmPrinter LLVMMipsAsmParser LLVMMSP430Info LLVMMSP430Desc LLVMMSP430CodeGen LLVMMSP430AsmPrinter LLVMMCParser LLVMMCJIT LLVMMCDisassembler LLVMMC LLVMLinker LLVMLTO LLVMJIT LLVMInterpreter LLVMInstrumentation LLVMInstCombine LLVMIRReader LLVMHexagonInfo LLVMHexagonDesc LLVMHexagonCodeGen LLVMHexagonAsmPrinter LLVMExecutionEngine LLVMDebugInfo LLVMCppBackendInfo LLVMCppBackendCodeGen LLVMCore LLVMCodeGen LLVMBitWriter LLVMBitReader LLVMAsmPrinter LLVMAsmParser LLVMAnalysis LLVMARMInfo LLVMARMDisassembler LLVMARMDesc LLVMARMCodeGen LLVMARMAsmPrinter LLVMARMAsmParser LLVMAArch64Utils LLVMAArch64Info LLVMAArch64Disassembler LLVMAArch64Desc LLVMAArch64CodeGen LLVMAArch64AsmPrinter LLVMAArch64AsmParser

KLEE_LIB_INC=$(addprefix $(RUN_DIR)/install/lib/klee/lib,$(KLEE_LIBS))
LLVM_LIB_INC=$(addprefix $(RUN_DIR)/install/lib/llvm/lib,$(LLVM_LIBS))


# @runtime items:
#
# user project Object targets
OBJS=$(addsuffix .o,$(basename $(wildcard project/src/*.c)))
SOBJS=$(addsuffix .o,$(basename $(wildcard project/src/*.s)))
#
# user project binary name
TARGET?=


### Usage
## project/ dir: create project, drop in source, edit harness.c, run docker container, mount project dir to test_build/project/ compile compile to *.o files in tmp/, link *.o tmp/, and then run this makefile with `make`


########################################
############ @runtime section ##########
########################################

all: target project/$(TARGET) preprocess project/build/bitcode/$(TARGET).interp.cpp project/build/bitcode/$(TARGET).interp.bc bitcode_other project/run_$(TARGET).sh


# build project Object files
.PHONY: target
target: $(SOBJS) $(OBJS)


project/src/%.o: project/src/%.s
	$(TASE_CLANG) -I$(INCLUDE_DIR)/tase/ -I$(INCLUDE_DIR)/traps/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


project/src/%.o: project/src/%.c
	$(TASE_CLANG) -I$(INCLUDE_DIR)/tase/ -I$(INCLUDE_DIR)/traps/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


# compile project
project/$(TARGET): project/build/proj.a
	/usr/bin/c++ -D_GLIBCXX_USE_CXX11_ABI=0 -fno-pie -no-pie -T$(TASE_LINK) -I$(INCLUDE_DIR)/openssl/ -Wall -Wextra -Wno-unused-parameter -O3 -o $$(pwd)/project/$(TARGET) -L$(RUN_DIR)/lib/ $$(pwd)/project/build/proj.a -rdynamic $$(pwd)/main.cpp.o -lz -lpthread -ltinfo -ldl -lm


# cartridge.log -> cartridgeInfo.txt for klee
.PHONY: preprocess
preprocess: project/build/$(TARGET).vars project/build/$(TARGET).tase
	cd project/ && ./$(TARGET) -tasePreProcess=TRUE


project/build/$(TARGET).vars: project/$(TARGET)
	python3 $(RUN_DIR)/parseltongue86/rosettastone.py project/$(TARGET) project/build/proj.a | sort -u > project/$(TARGET).vars


# combine libtase.a and project Objects
project/build/proj.a:
	ar crs project/build/proj.a $$(pwd)/project/src/*.o


# previously made project/build/everything.o
project/build/$(TARGET).tase: project/$(TARGET)
	nm --defined-only project/build/proj.a | grep -i " t " | cut -d' ' -f 3 > project/build/$(TARGET).tase


# create project bitcode files
project/build/bitcode/$(TARGET).interp.cpp:
	mkdir -p project/build/bitcode
	cd project && python3 $(RUN_DIR)/parseltongue86/parseltongue86.py -f build/$(TARGET).tase $(TARGET) $(INCLUDE_DIR)/tase/ > build/bitcode/$(TARGET).interp.cpp


project/build/bitcode/$(TARGET).interp.bc:
	$(CLANG) -fno-slp-vectorize -Wall -Wextra -emit-llvm -Wno-unused -O3 -std=c++11 -I$(INCLUDE_DIR)/tase/ -c project/build/bitcode/$(TARGET).interp.cpp -o project/build/bitcode/$(TARGET).interp.bc


# copy in klee bitcode items
.PHONY: bitcode_other
bitcode_other:
	cp klee_bitcode/* project/build/bitcode/


# create script to: point klee to bitcode, run the binary
project/run_$(TARGET).sh:
	echo '#/bin/bash' > project/run_$(TARGET).sh
	echo 'KLEE_RUNTIME_LIBRARY_PATH=build/bitcode/ ./$(TARGET)' >> project/run_$(TARGET).sh
	chmod +x project/run_$(TARGET).sh



######################################## 
############ @build section ############
########################################


.PHONY: setup
setup: klee main.cpp.o bitcode_files parseltongue resources


# copy cwd into install directory
.PHONY: resources
resources: main.cpp.o
	mv $$(pwd) $(RUN_DIR)/


# copy parseltongue over to install dir
.PHONY: parseltongue
parseltongue:
	mkdir -p  /TASE/parseltongue86/
	cp /TASE_BUILD/parseltongue86/parseltongue86.py /TASE_BUILD/parseltongue86/rosettastone.py /TASE/parseltongue86/
	cp -r /TASE_BUILD/parseltongue86/translator /TASE/parseltongue86/


# compile tase Objects
$(TASE_OBJSA): %.o: %.c $(TASE_CLANG)
	$(TASE_CLANG) -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(BUILD_DIR)/test/tase/include/  $(MODELED_FN_ARG) $< -o $@

$(TASE_OBJSC): %.o: %.S $(TASE_CLANG)
	$(TASE_CLANG) -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(BUILD_DIR)/test/tase/include/  $(MODELED_FN_ARG) $< -o $@


$(TASE_OBJSB): %.o: %.c
	$(CLANG) -c -O1 -I$(BUILD_DIR)/test/tase/include/ $< -o $@


$(TASE_SHIMOBJS): %.o: %.c $(TASE_CLANG)
	$(TASE_CLANG) -c -O0 $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


# compile musl objects, redefine symbols
# ar -> ld because otherwise get multiple definition errors from errno
lib/musl.o: $(TASE_CLANG)
	cp $(MUSL_PATH)/TASEConfig/config.mak_no_simd $(MUSL_PATH)/config.mak
	PATH="$(RUN_DIR)/bin:$${PATH}" $(MAKE) -C $(MUSL_PATH)
	cp $(BUILD_DIR)/test/libc/all.syms ./libtasec.syms
	ar crs libtasec.a $(MUSL_OBJS)
	mkdir -p ltbuild lib
	cd ltbuild && ar -x ../libtasec.a && ld -o ../lib/musl.o -r *.o
	rm -rf ltbuild
	./localize.sh lib/musl.o
	rm libtasec.syms
	rm libtasec.a


# compile soft float Objects
$(BUILD_DIR)/compiler-rt_soft_float/%.o: $(BUILD_DIR)/compiler-rt_soft_float/%.c
	$(CLANG) -c $< -o $@


# copy klee main, needed for project compilation
main.cpp.o: klee
	mv $(BUILD_DIR)/build_klee/tools/klee/CMakeFiles/klee.dir/main.cpp.o $$(pwd)/main.cpp.o


# copy klee bitcode files to install dir
.PHONY: bitcode_files
bitcode_files: klee
	mkdir -p klee_bitcode
	mv $(BUILD_DIR)/build_klee/$(KLEE_BUILD_TYPE)/lib/klee*.bc klee_bitcode/


lib/libtase.a: $(TASE_OBJS) lib/musl.o
	ar crs lib/libtase.a $(TASE_OBJS)


# create dummy project for compiling klee
klee: lib/libtase.a $(BUILD_DIR)/build_klee/lib/checksum.a $(RUN_DIR)/lib/libstp.a $(RUN_DIR)/lib/libminisat.a $(TASE_CLANG)
	mkdir -p $(BUILD_DIR)/build_klee/lib/
	cp lib/libtase.a $(BUILD_DIR)/build_klee/lib/
	cd $(BUILD_DIR)/build_klee/ && $(KLEE_ENV) cmake $(KLEE_OPTS) ../klee
	cp $(BUILD_DIR)/install/link.txt $(BUILD_DIR)/build_klee/tools/klee/CMakeFiles/klee.dir/
	$(MAKE) -C $(BUILD_DIR)/build_klee/
#	mkdir -p lib/klee/
#	mv /TASE_BUILD/build_klee/lib/libk*.a lib/klee/


$(BUILD_DIR)/build_klee/lib/checksum.a: $(CKSUM_OBJS)
	mkdir -p $(BUILD_DIR)/build_klee/lib/
	ar crs $(BUILD_DIR)/build_klee/lib/checksum.a $(CKSUM_OBJS)


$(BUILD_DIR)/test/microbenchmarks/concrete/cksum/%.o: $(BUILD_DIR)/test/microbenchmarks/concrete/cksum/%.c $(TASE_CLANG)
	$(TASE_CLANG) -I$(BUILD_DIR)/test/microbenchmarks/concrete/cksum/ -I$(INCLUDE_DIR)/tase/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


$(RUN_DIR)/lib/libstp.a: $(RUN_DIR)/lib/libminisat.a
	cd $(BUILD_DIR)/build_stp && cmake $(STP_OPTS) ../stp
	$(MAKE) -C $(BUILD_DIR)/build_stp/
	$(MAKE) -C $(BUILD_DIR)/build_stp/ install
	cp $(BUILD_DIR)/build_stp/lib/libstp.a $(RUN_DIR)/lib/


$(RUN_DIR)/lib/libminisat.a:
	cd $(BUILD_DIR)/build_minisat/ && cmake $(MINISAT_OPTS) ../minisat
	$(MAKE) -C $(BUILD_DIR)/build_minisat/
	$(MAKE) -C $(BUILD_DIR)/build_minisat/ install
	cp $(BUILD_DIR)/build_minisat/lib/libminisat.a $(RUN_DIR)/lib/


$(TASE_CLANG):
	cd $(BUILD_DIR)/build_llvm/ && cmake $(TSX_LLVM_OPTS) ../llvm
	$(MAKE) -C $(BUILD_DIR)/build_llvm/
	$(MAKE) -C $(BUILD_DIR)/build_llvm/ install


.PHONY: openssl
openssl:
	cd openssl && ./config $(SSL_OPTS)
	$(MAKE) -C $(BUILD_DIR)/openssl/ build_taseall
