set -e

function errmessage {
    echo "Something went wrong when running Microbenchmarks.  Consult error logs ConcreteOverheadBuildLog.txt and SlidingScaleBuildLog.txt for more info."
}
trap errmessage ERR
echo ""
echo "Running TASE concrete overhead microbenchmarks, followed by the sliding-scale test that \
measures performance degredation as larger amounts of symbolic computation are gradually introduced. \
See section 6 of the TASE paper for more info."

echo ""
echo "Results will be located in ConcreteOverheadMicrobenchmarksResults.txt and SlidingScaleResults.txt. \
This usually takes about 5 to 10 minutes."
echo ""

TEST_PATH=$(pwd)
MICRO_BENCH_PATH=$TEST_PATH/microbenchmarks

#Format builtin "time" shell command to output real time in seconds
TIMEFORMAT='%R'

STANDARD_ARGS=" -retryMax=1 -tranBBMax=16  -disable-opt  -noLog=TRUE"

#Concrete Overhead Tests

echo "Benchmark", "Time(s)", "Run" > ConcreteOverheadMicrobenchmarksResults.txt

rm -f ConcOverheadBuildLog.txt

#-------------------------------------------
#bigNum
echo "#define TASE_BIGNUM" > proj_defs.h

echo "Compiling code for BigNum concrete overhead test in TASE... "

cd $MICRO_BENCH_PATH/slidingscale/bigNum
./makeproj.sh >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh bigNum $MICRO_BENCH_PATH/slidingscale/bigNum  .  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1

BIGNUM_EVAL_CMD="./TASE -project=bigNum $STANDARD_ARGS -symIndex=-1 -numEntries=10000000 bigNum.interp.bc"
echo "Running bigNum microbenchmark"
for j in {0..4..1}
do
    echo "bigNum", `(time ( $BIGNUM_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcreteOverheadMicrobenchmarksResults.txt 2>&1
done

echo "" > proj_defs.h
#-----------------------------------------------
#Factor
echo "Compiling code for Factor concrete overhead test in TASE... "

cd $MICRO_BENCH_PATH/concrete/factor
./makeproj.sh  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh factor $MICRO_BENCH_PATH/concrete/factor . >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1

FACTOR_EVAL_CMD="./TASE -project=factor $STANDARD_ARGS factor.interp.bc"
echo "Running factor microbenchmark"
for j in {0..4..1}
do
    echo "Factor", `(time ( $FACTOR_EVAL_CMD > /dev/null 2>&1 )) |& cat `,$j >> ConcreteOverheadMicrobenchmarksResults.txt 2>&1
done

#--------------------------------------------
#Tsort
echo "Compiling code for tsort concrete overhead test in TASE... "
cd $MICRO_BENCH_PATH/concrete/tsort
./makeproj.sh  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh tsort $MICRO_BENCH_PATH/concrete/tsort .  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1

TSORT_EVAL_CMD="./TASE -project=tsort $STANDARD_ARGS tsort.interp.bc"
echo "Running tsort microbenchmark"
for j in {0..4..1}
do
    echo "Tsort", `(time ( $TSORT_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcreteOverheadMicrobenchmarksResults.txt 2>&1
done

#-------------------------------------------
#cksum
echo "Compiling code for cksum concrete overhead test in TASE... "
cd $MICRO_BENCH_PATH/concrete/cksum
./makeproj.sh  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh cksum $MICRO_BENCH_PATH/concrete/cksum .  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1

CKSUM_EVAL_CMD="./TASE -project=cksum $STANDARD_ARGS cksum.interp.bc"
echo "Running cksum microbenchmark"
for j in {0..4..1}
do
    echo "Cksum", `(time ( $CKSUM_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcreteOverheadMicrobenchmarksResults.txt 2>&1
done

#-------------------------------------------
#sha256
echo "Compiling code for sha256 concrete overhead test in TASE... "
cd $MICRO_BENCH_PATH/concrete/sha256
./makeproj.sh  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh sha256 $MICRO_BENCH_PATH/concrete/sha256 .  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1

SHA256_EVAL_CMD="./TASE -project=sha256 $STANDARD_ARGS sha256.interp.bc"
echo "Running sha256 microbenchmark"
for j in {0..4..1}
do
    echo "sha256", `(time ( $SHA256_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcreteOverheadMicrobenchmarksResults.txt 2>&1
done

#-------------------------------------------
#md5sum
echo "Compiling code for md5sum concrete overhead test in TASE... "
cd $MICRO_BENCH_PATH/concrete/md5sum
./makeproj.sh  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh md5sum $MICRO_BENCH_PATH/concrete/md5sum .  >> $TEST_PATH/ConcOverheadBuildLog.txt 2>&1

MD5SUM_EVAL_CMD="./TASE -project=md5sum $STANDARD_ARGS md5sum.interp.bc"
echo "Running md5sum microbenchmark"
for j in {0..4..1}
do
    echo "md5sum", `(time ( $MD5SUM_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcreteOverheadMicrobenchmarksResults.txt 2>&1
done


#-------------------------------------------
#Run the sliding scale microbenchmark

rm -f SlidingScaleBuildLog.txt

echo "Compiling code for and running sliding scale microbenchmark"
echo "#define TASE_BIGNUM" > proj_defs.h

cd $MICRO_BENCH_PATH/slidingscale/bigNum
./makeproj.sh  >> $TEST_PATH/SlidingScaleBuildLog.txt 2>&1
cd $TEST_PATH
./argsProjectLinkTase.sh bigNum $MICRO_BENCH_PATH/slidingscale/bigNum .  >> $TEST_PATH/SlidingScaleBuildLog.txt 2>&1

rm -f bigNumResultsTASE.csv

#ID is 0 for TASE, 1 for KLEE, 2 for S2E
echo "symIndex, time_s, ID" > SlidingScaleResults.txt

for j in {0..4..1}
do

    for i in {0..50000..1000}
    do
	        echo $i, `   (time( ./TASE -project=bigNum  -optimizeConstMemOps=TRUE  -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE   -use-cex-cache=TRUE -use-cache=FALSE  -retryMax=1 -tranBBMax=16 -modelDebug=FALSE -useCMS4=TRUE  -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE  -noLog=TRUE -symIndex=$i -numEntries=50000 bigNum.interp.bc >  /dev/null 2>&1) ) |&  cat `, 0 >> SlidingScaleResults.txt 2>&1


    done
done


echo "" > proj_defs.h
#---------------------------------
#Cleanup!

echo "Microbenchmarks completed.  Results are in ConcreteOverheadMicrobenchmarksResults.txt and SlidingScaleResults.txt"

rm -rf klee-out-*
rm -rf klee-last
rm -f *.interp.*
rm -f *.vars
