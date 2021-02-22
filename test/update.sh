#Point of this script is to update klee after its source files are changed, or the program we're testing (ex OpenSSL) is changed.
#Requirements: ver_lib.a and link.txt (with extra .o references) in current directory
#Outputs:  Moves ver_lib.a and link.txt to klee build directory, extracts object files, etc.  Gets us ready to make klee again.

#For now at least, we assume we're running update.sh from 1 directory above the project directory.
#Ex, we're running in $TASE_PATH/test/ rather than $TASE_PATH/test/fruit_basket
#Not married to this convention.  Feel free to refactor.  ABH 06/18/2018

#Currently running both "make" and "make lib" to get all the files needed from the target for use below.

set -e

NCPU=4
TASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
KLEE_CORE_DIR=$TASE_PATH/build_klee/lib/Core/CMakeFiles/kleeCore.dir
TEST_PATH=$TASE_PATH/test
#PROJECT=addMicrobenchmark
PROJECT=md5sum
#PROJECT_PATH=$TEST_PATH/$PROJECT
PROJECT_PATH=$TEST_PATH/microbenchmarks/concrete/md5sum/buffguard


#Do we still need this?
#cp $PROJECT_PATH/link.txt $KLEE_CORE_DIR
#pushd $KLEE_CORE_DIR
#ar -x $PROJECT_PATH/$PROJECT.a
#popd

#This is a hack to make the compiler recompile everything
touch $KLEE_CORE_DIR/Searcher.cpp.o

make -j $NCPU -C $TASE_PATH/build_klee/

cp $TASE_PATH/build_klee/bin/klee $TEST_PATH

python3 $TASE_PATH/parseltongue86/parseltongue86.py $TEST_PATH/klee $PROJECT_PATH/$PROJECT.tase > $TEST_PATH/$PROJECT.interp.cpp

#python3 $TASE_PATH/parseltongue86/rosettastone.py $TEST_PATH/klee $PROJECT_PATH/$PROJECT.a > $TEST_PATH/$PROJECT.vars
python3 $TASE_PATH/parseltongue86/rosettastone.py $TEST_PATH/klee ../build_klee/lib/proj.a > $TEST_PATH/$PROJECT.vars

#Compiling with -O3 directly causes vectorized operations to be emitted.  Unfortunately klee doesn't like that so we
#add the -fno-slp-vectorize option.

/opt/llvm-3.4.2/bin/clang++ -fno-slp-vectorize -Wall -Wextra -O3 -emit-llvm -std=c++11 -c $TEST_PATH/$PROJECT.interp.cpp -o $TEST_PATH/$PROJECT.interp.bc

/opt/llvm-3.4.2/bin/llvm-dis $TEST_PATH/$PROJECT.interp.bc

#Latest build drops debug output to files listed by PID of the form Monitor.PID1.PID2 etc
#This is just for cleanup
rm $TEST_PATH/Monitor*
rm $TEST_PATH/SUCCESS*
