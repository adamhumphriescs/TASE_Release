set -e

cat libtasec.syms | while read LIB
do
    objcopy --localize-symbol=$LIB musl.o
done

#These are some symbol redefinition hacks that help us link in much of
#libc from musl.  Specifically, the a_ctz_64 and a_clz_64 functions have
#bsr instructions when they're compiled in TASE, so we just trap on those for now
#and use a model in KLEE.
objcopy --redefine-syms=/TASE_BUILD/test/scripts/redefinedSF musl.o
objcopy --redefine-syms=/TASE_BUILD/test/scripts/redefinedStrConv musl.o

objcopy --redefine-sym sprintf=sprintf_tase musl.o
objcopy --redefine-sym printf=printf_tase musl.o
objcopy --redefine-sym puts=puts_tase_shim musl.o
objcopy --globalize-symbol=a_ctz_64 musl.o
objcopy --globalize-symbol=a_clz_64 musl.o
objcopy --redefine-sym a_ctz_64=a_ctz_64_tase musl.o
objcopy --redefine-sym a_clz_64=a_clz_64_tase musl.o

objcopy --redefine-sym calloc=calloc_tase_shim musl.o
objcopy --redefine-sym realloc=realloc_tase_shim musl.o
objcopy --redefine-sym malloc=malloc_tase_shim musl.o
objcopy --redefine-sym free=free_tase_shim musl.o
objcopy --redefine-sym getc_unlocked=getc_unlocked_tase_shim musl.o

#Changed because we now link in the definition of memcpy from musl, but still
#want to trap for efficiency.
objcopy --redefine-sym memcpy=memcpy_tase musl.o
objcopy --globalize-symbol=memcpy_tase musl.o

objcopy --redefine-sym main=tase_project_entry musl.o
