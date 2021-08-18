set -e

source ~/.bashrc

BUILD_DIR=$1
LIBTASEC_PATH=$2

pushd $LIBTASEC_PATH
./getclibs.sh
popd

cp $LIBTASEC_PATH/libtasec.a $BUILD_DIR/
pushd $BUILD_DIR
ar -x libtasec.a
popd

ld -r $BUILD_DIR/*.o -o $BUILD_DIR/everything.o
#nm everything.o | grep  "[0-9a-f] [tTdDgGrRsSvVwWC] " | cut -f3 -d ' ' > targetsyms

cat $LIBTASEC_PATH/all.syms | while read LIB
do
    objcopy --localize-symbol=$LIB $BUILD_DIR/everything.o
done


#These are some symbol redefinition hacks that help us link in much of
#libc from musl.  Specifically, the a_ctz_64 and a_clz_64 functions have
#bsr instructions when they're compiled in TASE, so we just trap on those for now
#and use a model in KLEE.
objcopy --redefine-syms=$TASE_ROOT_DIR/test/scripts/redefinedSF $BUILD_DIR/everything.o
objcopy --redefine-syms=$TASE_ROOT_DIR/test/scripts/redefinedStrConv $BUILD_DIR/everything.o

objcopy --redefine-sym sprintf=sprintf_tase $BUILD_DIR/everything.o
objcopy --redefine-sym printf=printf_tase $BUILD_DIR/everything.o
objcopy --redefine-sym puts=puts_tase_shim $BUILD_DIR/everything.o
objcopy --globalize-symbol=a_ctz_64 $BUILD_DIR/everything.o
objcopy --globalize-symbol=a_clz_64 $BUILD_DIR/everything.o
objcopy --redefine-sym a_ctz_64=a_ctz_64_tase $BUILD_DIR/everything.o
objcopy --redefine-sym a_clz_64=a_clz_64_tase $BUILD_DIR/everything.o

objcopy --redefine-sym calloc=calloc_tase_shim $BUILD_DIR/everything.o
objcopy --redefine-sym realloc=realloc_tase_shim $BUILD_DIR/everything.o
objcopy --redefine-sym malloc=malloc_tase_shim $BUILD_DIR/everything.o
objcopy --redefine-sym free=free_tase_shim $BUILD_DIR/everything.o
objcopy --redefine-sym getc_unlocked=getc_unlocked_tase_shim $BUILD_DIR/everything.o

#Changed because we now link in the definition of memcpy from musl, but still
#want to trap for efficiency.
objcopy --redefine-sym memcpy=memcpy_tase $BUILD_DIR/everything.o
objcopy --globalize-symbol=memcpy_tase $BUILD_DIR/everything.o
