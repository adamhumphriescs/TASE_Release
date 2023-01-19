SHELL:=/bin/bash
CFLAGS?=-O0
MAKEFLAGS:=-j 10 -k
dirs=$(realpath $(wildcard */))
results=$(addsuffix /resx5.txt,$(dirs))
shortresults=$(addsuffix /res.txt,$(dirs))

TSX?=

all: results.txt

.PHONY: clean %.clean
clean: $(addsuffix .clean,$(dirs)) tsort.clean

%.clean:
	$(MAKE) -C $* clean

progs: $(addsuffix /build/main,$(dirs))


%/build/main: %
	$(MAKE) CONTAINER=$(CONTAINER) CFLAGS="$(CFLAGS)" TSX=$(TSX) -C $< build/main

results.txt: $(results)
	cat $(results) > results.txt

shortresults.txt: $(shortresults)
	cat $(shortresults) > shortresults.txt

%/resx5.txt: progs
	$(MAKE) CONTAINER=$(CONTAINER) -C $* resx5.txt

%/res.txt: progs
	$(MAKE) CONTAINER=$(CONTAINER) -C $* res.txt
