#!/bin/bash

rm -f bigNumResultsTASE.csv

#ID is 0 for TASE, 1 for KLEE, 2 for S2E
echo "symIndex, time_s, ID" > SlidingScaleResults.txt

for j in {0..4..1}
do

    for i in {0..50000..1000}
    do
	        echo $i, `   cd build/ && (time( ./run.sh -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE   -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -modelDebug=FALSE -useCMS4=FALSE  -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -check-overshift=FALSE -singleStepping -noLog=TRUE - $i 50000 1 >  /dev/null 2>&1) ) |&  grep user | cut -d$'\t' -f2 `, 0 >> SlidingScaleResults.txt 2>&1


    done
done
