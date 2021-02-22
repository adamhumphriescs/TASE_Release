#DANGER: This script will drop the "minutes" part of time 

set -e

rm -f bigNumResultsTASE.csv

#ID is 0 for TASE, 1 for KLEE, 2 for S2E
#echo "symIndex, time(seconds), ID" > kleeBigNumTimes.csv
echo "symIndex, time_s, ID" > TASEBigNumLog

for j in {0..4..1}
do

    for i in {0..50000..1000}
    do
	echo $i, `   (time ./klee -project=bigNum -optimizeOvershiftChecks=TRUE -optimizeConstMemOps=TRUE  -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -taseDebug=FALSE  -testType=VERIFICATION -taseManager=TRUE -execMode=MIXED  -use-cex-cache=TRUE -use-cache=FALSE   -killFlagsHack=TRUE -skipFree=FALSE -enableBounceback=TRUE  -measureTime=FALSE -retryMax=1 -tranBBMax=16 -QRMaxWorkers=7 -modelDebug=FALSE -useCMS4=TRUE  -output-source=false -output-stats=false -output-istats=false    -use-call-paths=false -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -useXOROpt=TRUE -use-fast-cex-solver=FALSE -noLog=TRUE -symIndex=$i -numEntries=50000 bigNum.interp.bc)  |& grep "real" |& cut -d 'm' -f 2 |& cut -d 's' -f 1 `, 0 >> TASEBigNumLog
    
    
    done
done
