CONTAINER=tasetest
CFLAGS=-O0
TSX?=0

all: collect

.PHONY: short
short: concrete/shortresults.txt
	mv concrete/shortresults.txt results.txt

collect: concrete/results.txt slidingscale/bigNum/SlidingScaleResults.txt
	mv concrete/results.txt ConcreteResults.txt
	mv slidingscale/bigNum/SlidingScaleResults.txt SlidingScaleResults.txt

concrete/results.txt:
	$(MAKE) CONTAINER="$(CONTAINER)" CFLAGS="$(CFLAGS)" TSX="$(TSX)" -C concrete

concrete/shortresults.txt:
	$(MAKE) CONTAINER="$(CONTAINER)" CFLAGS="$(CFLAGS)" TSX="$(TSX)" -C concrete shortresults.txt

slidingscale/bigNum/SlidingScaleResults.txt:
	$(MAKE) CONTAINER="$(CONTAINER)" CFLAGS="$(CFLAGS)" TSX="$(TSX)" -C slidingscale/bigNum/
	$(MAKE) CONTAINER="$(CONTAINER)" CFLAGS="$(CFLAGS)" TSX="$(TSX)"  -j4 -C slidingscale/bigNum/ SlidingScaleResults.txt


clean:
	$(MAKE)  -C concrete clean
	$(MAKE) -C slidingscale/bigNum clean
