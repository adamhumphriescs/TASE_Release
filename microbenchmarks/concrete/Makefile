dirs=cksum md5sum sha256sum factor #$(realpath $(wildcard */))
SHELL:=/bin/bash
#MAKEFLAGS:= -j 4 -k

all: progs mixed interp

.PHONY: mixed mixeditems mixedres interp interpitems interpres clean progs

clean: $(addsuffix .clean,$(dirs))

%.clean: %
	$(MAKE) -C $< clean


mixed: mixeditems
interp: interpitems

progs: $(addsuffix .main,$(dirs))

mixeditems: $(addsuffix .mitem,$(dirs))

%.mitem: %
	$(MAKE) -C $< smallmixedtest && $(MAKE) -C $< mixedres

mixedres: $(addsuffix .mixed,$(dirs))

%.mixed: %
	echo ""; echo ""; echo $<; echo "test:"; cat $</mixedres.txt; echo "ref:"; cat $</ref.txt


interp: $(addsuffix .iitem,$(dirs))

%.iitem: %
	$(MAKE) -C $< smalltest && $(MAKE) -C $< interpres


interpres: $(addsuffix .interp,$(dirs))

tsort.interp:
	echo ""; echo ""; echo "tsort"; x=$$(diff <(tsort tsort/tsortShort) <(cat tsort/interpres.txt)); if [[ $$x ]]; then echo "test: FAIL"; else echo "test: PASS"; fi

%.interp: %
	echo ""; echo ""; echo $<; echo "test:"; cat $</interpres.txt; echo "ref:"; cat $</ref.txt;


%.main: %
	$(MAKE) -C $<
