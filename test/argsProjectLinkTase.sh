
set -e
source ~/.bashrc

NCPU=8

#TASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
TASE_PATH=$TASE_ROOT_DIR
#TEST_PATH=$TASE_PATH/test
KLEE_CORE_DIR=$TASE_PATH/build_klee/lib/Core/CMakeFiles/kleeCore.dir
#TEST_PATH=$TASE_PATH/projects/FloatTest


PROJECT=$1
PROJECT_PATH=$2
TASE_RUN_DIR=$3

make -j $NCPU -C $TASE_PATH/build_klee/ 

cp $TASE_PATH/build_klee/bin/klee $TASE_RUN_DIR/TASE

#Run preprocessing in TASE to dump cartridge info out once our static libraries are linked in at fixed addresses
./TASE -tasePreProcess=TRUE 

#Note -- replaced third arg of $TASE_RUN_DIR/$PROJECT.interp.nop with root tase dir 07/23/2021.  
python3 $TASE_PATH/parseltongue86/parseltongue86.py $TASE_RUN_DIR/TASE $PROJECT_PATH/$PROJECT.tase $TASE_PATH  > $TASE_RUN_DIR/$PROJECT.interp.cpp 
python3 $TASE_PATH/parseltongue86/rosettastone.py $TASE_RUN_DIR/TASE $PROJECT_PATH/proj.a > $TASE_RUN_DIR/tmp.vars

sort tmp.vars | uniq > $TASE_RUN_DIR/$PROJECT.vars

/opt/llvm-3.4.2/bin/clang++ -fno-slp-vectorize  -Wall -Wextra -emit-llvm -Wno-unused  -O3  -std=c++11 -I./tase/include/ -c $TASE_RUN_DIR/$PROJECT.interp.cpp -o $TASE_RUN_DIR/$PROJECT.interp.bc 

rm -f Monitor*
rm -f log*
rm -f LOG*
