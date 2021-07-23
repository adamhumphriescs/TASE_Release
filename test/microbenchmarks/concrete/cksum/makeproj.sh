set -e

source ~/.bashrc

TASE_CLANG=../../../../install_root/bin/clang
TASE_DIR=../../../../test/tase
KLEE_LIB_BUILD_DIR=../../../../build_klee/lib/
MODELED_FN_ARG="-mllvm -x86-tase-modeled-functions=$TASE_DIR/include/tase/core_modeled.h"
NO_FLOAT_ARG="-mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx"

rm -f  ./tmp/*

$TASE_CLANG -I"." -I$TASE_DIR/include/tase/ -c -O1 -DTASE_TEST $NO_FLOAT_ARG  $MODELED_FN_ARG  cksum.c harness.c make_byte_symbolic.c
cp make_byte_symbolic.o ./tmp/
cp cksum.o ./tmp/
cp harness.o ./tmp/

#Tase mem function traps, e.g. malloc_tase, free_tase
$TASE_CLANG -c -O1 $MODELED_FN_ARG $TASE_DIR/traps/mem_traps.c -o ./tmp/mem_traps.o

#LIBC----------------------------------------------
#Grab libTaseC
#Add libTaseC to project object files in tmp
#Create one "everything.o" file from all object files
#localize libc symbols (e.g., memcpy, memset, etc) in everything.o in tmp
../../../../test/scripts/localizeLibs.sh ./tmp ../../../../test/libc

#LIBTASE-------------------------------------------
$TASE_CLANG -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$TASE_DIR/include  $MODELED_FN_ARG $TASE_DIR/springboard.S -o $TASE_DIR/springboard.o
/opt/llvm-3.4.2/bin/clang -c -O1 -I$TASE_DIR/include $TASE_DIR/log.c -o $TASE_DIR/log.o
/opt/llvm-3.4.2/bin/clang -c -O1 -I$TASE_DIR/include $TASE_DIR/common.c -o $TASE_DIR/common.o

$TASE_CLANG -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$TASE_DIR/include  $MODELED_FN_ARG $TASE_DIR/modeled/exit_tase.c -o $TASE_DIR/modeled/exit_tase.o

cp $TASE_DIR/common.o ./tmp/
cp $TASE_DIR/springboard.o ./tmp/
cp $TASE_DIR/log.o ./tmp/
cp $TASE_DIR/modeled/exit_tase.o ./tmp/
#----------------------------------------------
#Float emulation
$TASE_ROOT_DIR/compiler-rt_soft_float/buildSF.sh ./tmp/


cd ./tmp/
ar -r proj.a everything.o springboard.o log.o common.o  exit_tase.o sf_native_routines.o
cd ..
cp ./tmp/proj.a .
cp ./tmp/proj.a $KLEE_LIB_BUILD_DIR
