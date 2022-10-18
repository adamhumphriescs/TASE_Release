dirs=cksum md5sum sha256sum factor # $(realpath $(wildcard */))
SHELL:=/bin/bash
CFLAGS?=-O0

#MAKEFLAGS:= -j 4 -k

all: progs mixedres

.PHONY: mixed mixeditems mixedres interp interpitems interpres clean progs tsort

clean: $(addsuffix .clean,$(dirs))

%.clean: %
	$(MAKE) -C $< clean


progs: $(addsuffix .main,$(dirs))

mixeditems: $(addsuffix .mitem,$(dirs)) tsort.mitem

interpitems: $(addsuffix .mitem,$(dirs)) tsort.iitem

%.mitem: %
	$(MAKE) -C $< smallmixedtest && $(MAKE) -C $< mixedres

mixedres: $(addsuffix .mixed,$(dirs)) tsort.mm interpitems

tsort.mm: tsort.mitem
	echo ""; echo ""; echo "tsort"; x=$$(diff <(tsort tsort/tsortShort) <(cat tsort/mixedred.txt)); if [[ $$x ]]; then echo "test: FAIL"; else echo "test: PASS"; fi

%.mixed: % $(addsuffix .mitem,$(dirs)) tsort.mitem
	echo ""; echo ""; echo $<; echo "test:"; cat $</mixedres.txt; echo "ref:"; cat $</ref.txt


%.iitem: %
	$(MAKE) -C $< smalltest && $(MAKE) -C $< interpres

interpres: $(addsuffix .interp,$(dirs)) tsort.ii mixeditems

tsort.ii: tsort.iitem $(addsuffix .iitem,$(dirs))
	echo ""; echo ""; echo "tsort"; x=$$(diff <(tsort tsort/tsortShort) <(cat tsort/interpres.txt)); if [[ $$x ]]; then echo "test: FAIL"; else echo "test: PASS"; fi

%.interp: % $(addsuffix .iitem,$(dirs)) tsort.iitem
	echo ""; echo ""; echo $<; echo "test:"; cat $</interpres.txt; echo "ref:"; cat $</ref.txt;

%.main: %
	$(MAKE) CFLAGS="$(CFLAGS)" -C $<
