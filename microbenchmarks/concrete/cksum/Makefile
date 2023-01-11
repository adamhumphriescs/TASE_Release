ROOT?=/project
BIN?=main
CFLAGS?=-O0
USER=$$(id -u):$$(id -g)
CONTAINER=tasetest
DOCKER=docker run --user $(USER) --rm --mount type=bind,src=$$(pwd),dst=/project/ $(CONTAINER) bash

TSX?=

SMALL=../harness.c
LARGE=../GutenburgDictionary.txt
all: build/main build/obj.dump


build/main:
	$(DOCKER) -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" TSX="$(TSX)" -f build.Makefile'

.PHONY: build/obj.dump clean
build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/* res*.txt interpres*.txt mixedres*.txt


#.PRECIOUS:build/Monitor.interp% interp_time% build/Monitor.mixed% mixed_time% mixedres%.txt interpres%.txt
build/Monitor.interp% interp_time%:
ifeq ($(TSX), 1)
	bash -c 'cd build && { time ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) 2>1 ; } 2> ../interp_time$*'
else
	bash -c 'cd build && { time ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) 2>1 ; } 2> ../interp_time$*'
endif

build/Monitor.mixed% mixed_time%:
ifeq ($(TSX), 1)
	bash -c 'cd build && { time ./run.sh -dontFork -taseManager=false -check-overshift=false -modelDebug -log=$(notdir $@) - $(LARGE) 2>1 ; } 2> ../mixed_time$*'
else
	bash -c 'cd build && { time ./run.sh -dontFork -taseManager=false -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(LARGE) 2>1 ; } 2> ../mixed_time$*'
endif

ref.txt:
	cd build/ && cksum $(LARGE) > ../ref.txt

shortref.txt:
	cd build/ && cksum $(SMALL) > ../shortref.txt

mixedres%.txt: build/Monitor.mixed%
	grep $(LARGE) $< | tail -n1 > $@

interpres%.txt: build/Monitor.interp% 
	grep $(SMALL) $< | tail -n1 > $@


.PHONY: resx5.txt
resx5.txt: cleanres res_1.txt res_2.txt res_3.txt res_4.txt res_5.txt
	echo "cksum:" > resx5.txt
	cat res_*.txt >> resx5.txt

.PHONY: res.txt
res.txt: cleanres res_1.txt
	echo "cksum:" > res.txt
	cat res_1.txt >> res.txt


.PHONY: cleanres
cleanres:
	rm -f res_*.txt mixedres*.txt interpres*.txt Monitor.mixed* Monitor.interp*



res_%.txt: ref.txt shortref.txt mixedres%.txt interpres%.txt
	echo "  rep$*:" >> $@
	diff -q shortref.txt interpres$*.txt &>/dev/null; x=$$?; if [ $$x -ne 0 ]; then echo "    interp: FAIL"; else echo "    interp: PASS"; fi >> $@
	diff -q ref.txt mixedres$*.txt &>/dev/null; y=$$?; if [ $$y -ne 0 ]; then echo "    mixed: FAIL, $$(grep user mixed_time$* | awk '{print $$2}')"; else echo "    mixed: PASS, $$(grep user mixed_time$* | awk '{print $$2}')"; fi >> $@
