ROOT?=/project
BIN?=main
CFLAGS=-O0
SHELL:=bash
USER=-u $$(id -u):$$(id -g)
DOCKER=docker run --rm $(USER) --mount type=bind,src=$$(pwd),dst=/project/ tase bash
all: main


main: 
	$(DOCKER) -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'


test:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY - 0 50 1


smalltest:
	cd build/ && ./run.sh -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -useCMS4=FALSE  -use-legacy-independent-solver=FALSE -UseCanonicalization=TRUE -check-overshift=FALSE -output-source=TRUE -output-module=TRUE -optimizeOvershiftChecks=FALSE -modelDebug -taseDebug -debug-dump-stp-queries -singleStepping - 0 100 1 #   

gdbtest:
	cd build/ && env KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ gdb --args main --project=main -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -useCMS4=FALSE  -use-legacy-independent-solver=FALSE -UseCanonicalization=TRUE -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping - 0 100 1

mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping  - 25000 50000 1

SlidingScaleResults.txt: res1 res2 res3 res4
	echo "symIndex, time_s" > SlidingScaleResults.txt
	cat res* > SlidingScaleResults.txt
	rm res*

res%:
	for i in {0..50000..1000}; \
	do \
		$(DOCKER) -c "cd /project/build/ && { time ./run.sh -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE   -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -modelDebug=FALSE -useCMS4=FALSE  -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -check-overshift=FALSE -singleStepping -log=false - $$i 500 1 2>1 >/dev/null ; } 2>&1 | grep user | awk '"'{print "'"$$i"'", $$2}'"' >> ../res$*" ; \
	done

objdump:
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/*
