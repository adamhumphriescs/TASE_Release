#Small helper script to compile native soft float functions into a single object
#file and dropt the result (sf_native_routines.o) at the location in arg 1.
set -e


FILEDEST=$1

source ~/.bashrc

cd  $TASE_ROOT_DIR/compiler-rt_soft_float/

rm -f *.o

/opt/llvm-3.4.2/bin/clang -c *.c

ld -r *.o -o sf_native_routines.o

cd -

cp  $TASE_ROOT_DIR/compiler-rt_soft_float/sf_native_routines.o $FILEDEST
