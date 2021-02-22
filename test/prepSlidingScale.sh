
set -e

NCPU=8

#Need to run makeproj.sh in sliding scal directory first

TASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
TEST_PATH=$TASE_PATH/test
KLEE_CORE_DIR=$TASE_PATH/build_klee/lib/Core/CMakeFiles/kleeCore.dir

PROJECT=bigNum
PROJECT_PATH=$TEST_PATH/microbenchmarks/slidingscale/$PROJECT


make -j  $NCPU -C $TASE_PATH/build_klee/

cp $TASE_PATH/build_klee/bin/klee $TEST_PATH

#Run preprocessing in TASE to dump cartridge info out once our static libraries are linked in at fixed addresses
./klee -tasePreProcess=TRUE 

python3 $TASE_PATH/parseltongue86/parseltongue86.py $TEST_PATH/klee $PROJECT_PATH/$PROJECT.tase $TEST_PATH/$PROJECT.interp.nop  > $TEST_PATH/$PROJECT.interp.cpp 
python3 $TASE_PATH/parseltongue86/rosettastone.py $TEST_PATH/klee $PROJECT_PATH/proj.a > $TEST_PATH/tmp.vars

#Add in vars for stdlib 
#python3 $TASE_PATH/parseltongue86/rosettastone.py $TEST_PATH/klee ../build_klee/lib/libtasec.a >> $TEST_PATH/tmp.vars

sort tmp.vars | uniq > $TEST_PATH/$PROJECT.vars

/opt/llvm-3.4.2/bin/clang++  -fno-slp-vectorize -Wall -Wextra -emit-llvm  -O3  -std=c++11 -I./tase/include/ -c $TEST_PATH/$PROJECT.interp.cpp -o $TEST_PATH/$PROJECT.interp.bc

rm Monitor*
rm log*
