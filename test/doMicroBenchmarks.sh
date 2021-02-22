set -e

TEST_PATH=$(pwd)
MICRO_BENCH_PATH=$TEST_PATH/microbenchmarks

#Format builtin "time" shell command to output real time in seconds
TIMEFORMAT='%R'

STANDARD_ARGS=" -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -taseDebug=FALSE  -testType=VERIFICATION -taseManager=TRUE -execMode=MIXED  -use-cex-cache=TRUE -use-cache=FALSE   -killFlagsHack=TRUE -skipFree=FALSE -enableBounceback=TRUE  -measureTime=FALSE -retryMax=1 -tranBBMax=16 -QRMaxWorkers=7 -modelDebug=FALSE -useCMS4=TRUE  -output-source=false -output-stats=false -output-istats=false -disable-opt   -use-call-paths=false -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -useXOROpt=TRUE -use-fast-cex-solver=FALSE -noLog=TRUE"

#Concrete Overhead Tests

echo "Benchmark", "Time(s)", "Run" > ConcOverheadLog.txt


#-------------------------------------------
#bigNum
echo "#define TASE_BIGNUM" > proj_defs.h

cd $MICRO_BENCH_PATH/slidingscale/bigNum
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh bigNum $MICRO_BENCH_PATH/slidingscale/bigNum  

BIGNUM_EVAL_CMD="./klee -project=bigNum $STANDARD_ARGS -symIndex=-1 -numEntries=10000000 bigNum.interp.bc"
echo "Running bigNum microbenchmark"
for j in {0..4..1}
do
    echo "bigNum", `(time ( $BIGNUM_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcOverheadLog.txt 2>&1
done

echo "" > proj_defs.h
#-----------------------------------------------
#Factor
cd $MICRO_BENCH_PATH/concrete/factor
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh factor $MICRO_BENCH_PATH/concrete/factor

FACTOR_EVAL_CMD="./klee -project=factor $STANDARD_ARGS factor.interp.bc"
echo "Running factor microbenchmark"
for j in {0..4..1}
do
    echo "Factor", `(time ( $FACTOR_EVAL_CMD > /dev/null 2>&1 )) |& cat `,$j >> ConcOverheadLog.txt 2>&1
done

#--------------------------------------------
#Tsort
cd $MICRO_BENCH_PATH/concrete/tsort
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh tsort $MICRO_BENCH_PATH/concrete/tsort

TSORT_EVAL_CMD="./klee -project=tsort $STANDARD_ARGS tsort.interp.bc"
echo "Running tsort microbenchmark"
for j in {0..4..1}
do
    echo "Tsort", `(time ( $TSORT_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcOverheadLog.txt 2>&1
done

#-------------------------------------------
#cksum
cd $MICRO_BENCH_PATH/concrete/cksum
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh cksum $MICRO_BENCH_PATH/concrete/cksum

CKSUM_EVAL_CMD="./klee -project=cksum $STANDARD_ARGS cksum.interp.bc"
echo "Running cksum microbenchmark"
for j in {0..4..1}
do
    echo "Cksum", `(time ( $CKSUM_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcOverheadLog.txt 2>&1
done

#-------------------------------------------
#sha256
cd $MICRO_BENCH_PATH/concrete/sha256
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh sha256 $MICRO_BENCH_PATH/concrete/sha256

SHA256_EVAL_CMD="./klee -project=sha256 $STANDARD_ARGS sha256.interp.bc"
echo "Running sha256 microbenchmark"
for j in {0..4..1}
do
    echo "sha256", `(time ( $SHA256_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcOverheadLog.txt 2>&1
done

#-------------------------------------------
#md5sum
cd $MICRO_BENCH_PATH/concrete/md5sum
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh md5sum $MICRO_BENCH_PATH/concrete/md5sum

MD5SUM_EVAL_CMD="./klee -project=md5sum $STANDARD_ARGS md5sum.interp.bc"
echo "Running md5sum microbenchmark"
for j in {0..4..1}
do
    echo "md5sum", `(time ( $MD5SUM_EVAL_CMD > /dev/null 2>&1 )) |& cat `, $j >> ConcOverheadLog.txt 2>&1
done


#-------------------------------------------
#Run the sliding scale microbenchmark
echo "Running sliding scale microbenchmark"
echo "#define TASE_BIGNUM" > proj_defs.h

cd $MICRO_BENCH_PATH/slidingscale/bigNum
./makeproj.sh
cd $TEST_PATH
./argsProjectLinkTase.sh bigNum $MICRO_BENCH_PATH/slidingscale/bigNum

rm -f bigNumResultsTASE.csv

#ID is 0 for TASE, 1 for KLEE, 2 for S2E
echo "symIndex, time_s, ID" > TASEBigNumLog

for j in {0..4..1}
do

    for i in {0..50000..1000}
    do
	        echo $i, `   (time( ./klee -project=bigNum -optimizeOvershiftChecks=TRUE -optimizeConstMemOps=TRUE  -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -taseDebug=FALSE  -testType=VERIFICATION -taseManager=TRUE -execMode=MIXED  -use-cex-cache=TRUE -use-cache=FALSE   -killFlagsHack=TRUE -skipFree=FALSE -enableBounceback=TRUE  -measureTime=FALSE -retryMax=1 -tranBBMax=16 -QRMaxWorkers=7 -modelDebug=FALSE -useCMS4=TRUE  -output-source=false -output-stats=false -output-istats=false    -use-call-paths=false -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -useXOROpt=TRUE -use-fast-cex-solver=FALSE -noLog=TRUE -symIndex=$i -numEntries=50000 bigNum.interp.bc >  /dev/null 2>&1) ) |&  cat `, 0 >> TASEBigNumLog 2>&1


    done
done


echo "" > proj_defs.h
#---------------------------------
#Cleanup!

rm -rf klee-out-*
rm -rf klee-last
rm *.interp.*
rm *.vars
