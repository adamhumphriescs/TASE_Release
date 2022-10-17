ROOT?=/project
BIN?=main
CFLAGS=-O1

all: main


main: 
	docker run --user $$(id -u):$$(id -g) --rm -it --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'


test:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY - 0 50 1


smalltest:
	cd build/ && ./run.sh -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -useCMS4=FALSE  -use-legacy-independent-solver=FALSE -UseCanonicalization=TRUE -check-overshift=FALSE -output-source=TRUE -output-module=TRUE -optimizeOvershiftChecks=FALSE -modelDebug -taseDebug -debug-dump-stp-queries -singleStepping - 0 100 1 #   

gdbtest:
	cd build/ && env KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ gdb --args main --project=main -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE  -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -useCMS4=FALSE  -use-legacy-independent-solver=FALSE -UseCanonicalization=TRUE -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping - 0 100 1

mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping  - 25000 50000 1

objdump:
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/*
