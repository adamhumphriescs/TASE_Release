ROOT?=/project
BIN?=main
CFLAGS=-O0
SHELL:=bash
USER=-u $$(id -u):$$(id -g)

TSX?=

DOCKER=docker run --rm $(USER) --mount type=bind,src=$$(pwd),dst=/project/ $(CONTAINER) bash
all: main


main: 
	$(DOCKER) -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" TSX="$(TSX)" -f build.Makefile'


SlidingScaleResults.txt: res1 res2 res3 res4
	echo "symIndex, time_s" > SlidingScaleResults.txt
	cat res* > SlidingScaleResults.txt
	rm res*

res%:
ifeq ($(TSX), 1)
	for i in {0..50000..1000}; \
	do \
	$(DOCKER) -c "cd /project/build/ && { time ./run.sh -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE   -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -modelDebug=FALSE -useCMS4=FALSE -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -check-overshift=FALSE -log=false - $$i 50000 1 2>1 >/dev/null ; } 2>&1 | grep user | awk '"'{print "'"$$i"'", $$2}'"' >> ../res$*" ; \
done

else
	for i in {0..50000..1000}; \
	do \
	$(DOCKER) -c "cd /project/build/ && { time ./run.sh -optimizeConstMemOps=TRUE -use-forked-solver=FALSE -rewrite-equalities=FALSE -use-independent-solver=TRUE   -use-cex-cache=TRUE -use-cache=FALSE -retryMax=1 -tranBBMax=16 -modelDebug=FALSE -useCMS4=FALSE  -use-legacy-independent-solver=TRUE -UseCanonicalization=TRUE -check-overshift=FALSE -singleStepping -log=false - $$i 50000 1 2>1 >/dev/null ; } 2>&1 | grep user | awk '"'{print "'"$$i"'", $$2}'"' >> ../res$*" ; \
	done
endif

objdump:
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/*
