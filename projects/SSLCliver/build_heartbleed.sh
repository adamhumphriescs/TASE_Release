set -e
source ~/.bashrc
INPUTS=./src/*
PROJ_NAME=`basename "$PWD"`

TASE_CLANG=$TASE_ROOT_DIR/install_root/bin/clang
TASE_DIR=$TASE_ROOT_DIR/test/tase
KLEE_LIB_BUILD_DIR=$TASE_ROOT_DIR/build_klee/lib
MODELED_FN_ARG="-mllvm -x86-tase-modeled-functions=$TASE_DIR/include/tase/core_modeled.h"
NO_FLOAT_ARG="-mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-sse4 -mno-80387 -mno-avx"
OBJ_DIR=./build/obj

rm -rf ./src/*
cp ../utils/make_byte_symbolic.c ./src/
cp ./utils/sslharness_heartbeat.c ./src/
cp ./utils/TA.crt .

rm -rf  $OBJ_DIR/*
cp $INPUTS $OBJ_DIR/
cd $OBJ_DIR

#Instrument/Compile the project files.  harness.c has been dropped in by now.----
$TASE_CLANG -I"." -I$TASE_DIR/include/tase/ -c -O1 -DTASE_TEST $NO_FLOAT_ARG  $MODELED_FN_ARG  *.c
cp ../../../../openssl/libtasessl.a .
ar -x libtasessl.a
rm libtasessl.a

echo "#define TASE_OPENSSL" > ../../../../test/proj_defs.h

#Shims---------------------------------------------------------------------------
#Tase mem function traps, e.g. malloc_tase, free_tase
#Check this for inlining and 64 bit return value
$TASE_CLANG -c -O0 $NO_FLOAT_ARG $MODELED_FN_ARG $TASE_DIR/traps/tase_shims.c 

#LIBC----------------------------------------------------------------------------
#Grab libTaseC
#Add libTaseC to project object files in tmp
#Create one "everything.o" file from all object files
#localize libc symbols (e.g., memcpy, memset, etc) in everything.o in tmp
$TASE_ROOT_DIR/test/scripts/localizeLibs.sh  .  $TASE_ROOT_DIR/test/libc
objcopy --redefine-sym main=tase_project_entry everything.o

#Generate .tase file with names of functions we'll need IR for later on
$TASE_ROOT_DIR/test/scripts/getTASESyms.sh everything.o $PROJ_NAME

#Omit the a_clz_64 and a_ctz_64 fns from IR generation bc they have bsr deps and
#we trap on them anyway.
grep -v "a_c.*z_64_tase" $PROJ_NAME.tase  > $PROJ_NAME.tase_tmp
cp $PROJ_NAME.tase_tmp $PROJ_NAME.tase
cp $PROJ_NAME.tase ../../

#Sanity Check -- Are there any undefined symbols we need to instrument?-----------
SYMBOL_FAILURE="false"

if false; then 
nm everything.o | cut -c 18- | grep "^U " | cut -f2 -d" " > undefined_proj_syms
cat undefined_proj_syms | while read SYMBOL
do
    if [[ "$SYMBOL" =~ ^(sb_modeled|sb_reopen|target_main)$ ]] ; then
	continue
    elif [[ "$SYMBOL" == *_tase* ]]; then
	continue
    else
	echo "Found undefined symbol: " $SYMBOL 
	echo "Found undefined symbol: " $SYMBOL >> undefined_sym_log
    fi
    
done
if  test -f "undefined_sym_log" ; then
    echo "ERROR: TASE build stopped due to undefined symbol "
    exit 1
fi

fi
#LIBTASE--------------------------------------------------------------------------
$TASE_CLANG -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$TASE_DIR/include  $MODELED_FN_ARG $TASE_DIR/springboard.S 
$TASE_CLANG -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$TASE_DIR/include  $MODELED_FN_ARG $TASE_DIR/modeled/exit_tase.c
$TASE_ROOT_DIR/install_root/llvm-3.4.2/bin/clang -c -O1 -I$TASE_DIR/include $TASE_DIR/log.c 
$TASE_ROOT_DIR/install_root/llvm-3.4.2/bin/clang -c -O1 -I$TASE_DIR/include $TASE_DIR/common.c 

#---------------------------------------------------------------------------------
#Compile and add in soft float emulation routines.  These are native routines like __adddf3
#that the interpreter can use to perform limited floating point arithmetic on concrete data.
$TASE_ROOT_DIR/compiler-rt_soft_float/buildSF.sh .

#Archive the instrumented code in everything.o along with some support functions--
ar -r proj.a everything.o springboard.o log.o common.o  exit_tase.o sf_native_routines.o

cp proj.a $KLEE_LIB_BUILD_DIR
cp proj.a ../../
cd ../..

echo "Running argsProjectLinkTase "

$TASE_ROOT_DIR/test/argsProjectLinkTase.sh $PROJ_NAME . .

cp $PROJ_NAME.interp.* ./build/bitcode/
#rm $PROJ_NAME.interp.*
