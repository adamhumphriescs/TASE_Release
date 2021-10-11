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
TASE_OBJSB=$(addprefix $(TASE_DIR)/,log.o common.o)
TASE_OBJSC=$(addprefix $(TASE_DIR)/,springboard.o)
TASE_SHIMOBJS=$(TASE_DIR)/traps/tase_shims.o
TASE_OBJS=$(TASE_OBJSA) $(TASE_OBJSC) $(TASE_OBJSB) $(TASE_SHIMOBJS) $(SFLOAT_OBJS)


# dummy project vars
CKSUM_OBJS=$(addsuffix .o,$(basename $(wildcard $(BUILD_DIR)/test/microbenchmarks/concrete/cksum/*.c)))

# Klee CMAKE variables
KLEE_BUILD_TYPE=Release+Debug+Asserts

KLEE_ENV=CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 -fno-pie -no-pie -T$(RUN_DIR)/tase_link.ld -I$(INCLUDE_DIR)/openssl/"

KLEE_OPTS=-DCMAKE_INSTALL_PREFIX="$(RUN_DIR)" -DLLVM_CONFIG_BINARY="$(RUN_DIR)/llvm-3.4.2/bin/llvm-config" -DLLVMCC="$(CLANG)" -DLLVMCXX="$(CLANG)++" -DENABLE_KLEE_UCLIBC=FALSE -DENABLE_POSIX_RUNTIME=FALSE -DENABLE_SOLVER_STP=TRUE -DSTP_DIR="$(BUILD_DIR)/build_stp" -DCMAKE_BUILD_TYPE=Release -DENABLE_KLEE_ASSERTS=FALSE -DENABLE_UNIT_TESTS=FALSE -DENABLE_SYSTEM_TESTS=FALSE -DENABLE_DOCS=FALSE -DLLVM_INCLUDE_DIRS="$(RUN_DIR)/include/llvm-3.4.2/include/" -DLLVM_LIBRARY_DIRS="$(RUN_DIR)/include/llvm-3.4.2/lib/" -DKLEE_RUNTIME_BUILD_TYPE=$(KLEE_BUILD_TYPE)


# @runtime items:
#
# user project Object targets
OBJS=$(addsuffix .o,$(basename $(wildcard project/src/*.c) $(wildcard project/src/*.s)))
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
target: $(OBJS)

project/src/%.o: project/src/%.c
	$(TASE_CLANG) -I$(INCLUDE_DIR)/tase -I$(INCLUDE_DIR)/traps/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


project/src/%.o: project/src/%.s
	$(TASE_CLANG) -I$(INCLUDE_DIR)/tase/ -I$(INCLUDE_DIR)/traps/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


# compile project
project/$(TARGET): project/build/$(TARGET).tase project/build/$(TARGET).vars
	/usr/bin/c++ -D_GLIBCXX_USE_CXX11_ABI=0 -fno-pie -no-pie -T$(TASE_LINK) -I$(INCLUDE_DIR)/openssl/ -Wall -Wextra -Wno-unused-parameter -O3 -o project/$(TARGET) -rdynamic main.cpp.o project/build/proj.a prereqs.a -L$(RUN_DIR)/install_root/llvm-3.4.2/lib -lz -lpthread -ltinfo -ldl -lm -lz -lpthread -ltinfo -ldl -lm


# cartridge.log -> cartridgeInfo.txt for klee
.PHONY: preprocess
preprocess:
	cd project/ && ./$(TARGET) -tasePreProcess=TRUE


# create proj.a from libtase.a, libtasec.a, project Objects

project/build/$(TARGET).vars: project/build/proj.a
	python3 $(RUN_DIR)/parseltongue86/rosettastone.py project/$(TARGET) project/build/proj.a | sort -u > project/$(TARGET).vars


project/build/proj.a:
	./combine_libs.sh $(BUILD_DIR)/build_klee/lib/proj.a $$(pwd)/libtase.a project/src/*.o


# used to use project/build/everything.o
project/build/$(TARGET).tase: project/build/proj.a
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
resources:
	cp -r $$(PWD) $(RUN_DIR)/


# copy parseltongue over to install dir
.PHONY: parseltongue
parseltongue:
	mkdir -p  /TASE/parseltongue86/translator
	cp /TASE_BUILD/parseltongue86/parseltongue86.py /TASE_BUILD/parseltongue86/rosettastone.py /TASE/parseltongue86/
	cp -r /TASE_BUILD/parseltongue86/translator/ /TASE/parseltongue86/translator/


# compile tase Objects
$(TASE_OBJSA): %.o: %.c
	$(TASE_CLANG) -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(BUILD_DIR)/test/tase/include/  $(MODELED_FN_ARG) $< -o $@

$(TASE_OBJSC): %.o: %.S
	$(TASE_CLANG) -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(BUILD_DIR)/test/tase/include/  $(MODELED_FN_ARG) $< -o $@


$(TASE_OBJSB): %.o: %.c
	$(CLANG) -c -O1 -I$(BUILD_DIR)/test/tase/include/ $< -o $@


$(TASE_SHIMOBJS): $(TASE_DIR)/traps/tase_shims.c
	$(TASE_CLANG) -c -O0 $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@


# compile musl objects, redefine symbols
# ar -> ld because otherwise get multiple definition errors from errno
musl.o:
	cp $(MUSL_PATH)/TASEConfig/config.mak_no_simd $(MUSL_PATH)/config.mak
	make -C $(MUSL_PATH) -j 8
	cp $(BUILD_DIR)/test/libc/all.syms ./libtasec.syms
	ar -r libtasec.a $(MUSL_OBJS)
	mkdir -p ltbuild
	cd ltbuild && ar -x ../libtasec.a && ld -o ../musl.o -r *.o
	rm -rf ltbuild
	./localize.sh
	rm libtasec.syms
	rm libtasec.a


# compile soft float Objects
$(BUILD_DIR)/compiler-rt_soft_float/%.o: $(BUILD_DIR)/compiler-rt_soft_float/%.c
	$(CLANG) -c $< -o $@


# copy klee main, needed for project compilation
main.cpp.o: klee
	cp $(BUILD_DIR)/build_klee/tools/klee/CMakeFiles/klee.dir/main.cpp.o .


# copy klee bitcode files to install dir
.PHONY: bitcode_files
bitcode_files:
	mkdir -p klee_bitcode 
	cp $(BUILD_DIR)/build_klee/$(KLEE_BUILD_TYPE)/lib/klee*.bc klee_bitcode/


libtase.a: $(TASE_OBJS) musl.o
	./combine_libs.sh $$(pwd)/libtase.a $(TASE_OBJS) $(BUILD_DIR)/build_stp/lib/*.a $(RUN_DIR)/lib/libminisat.a $(RUN_DIR)/llvm-3.4.2/lib/*.a $$(pwd)/musl.o
	rm musl.o


# create dummy project for compiling klee
klee: $(BUILD_DIR)/build_klee/lib/proj.a
	cd $(BUILD_DIR)/build_klee/ && $(KLEE_ENV) cmake $(KLEE_OPTS) ../klee && make -j 8


$(BUILD_DIR)/build_klee/lib/proj.a: $(CKSUM_OBJS) libtase.a
	mkdir -p $(BUILD_DIR)/build_klee/lib/
	./combine_libs.sh $(BUILD_DIR)/build_klee/lib/proj.a $$(pwd)/libtase.a $(CHECKSUM_OBJS)


$(BUILD_DIR)/test/microbenchmarks/concrete/cksum/%.o: $(BUILD_DIR)/test/microbenchmarks/concrete/cksum/%.c
	$(TASE_CLANG) -I$(BUILD_DIR)/test/microbenchmarks/concrete/cksum/ -I$(INCLUDE_DIR)/tase/ -c -O1 -DTASE_TEST $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@
