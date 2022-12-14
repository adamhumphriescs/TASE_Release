ROOT?=/project
BIN?=main
CFLAGS?=-O0
USER=--user $$(id -u):$$(id -g)
CONTAINER?=tasetest
DOCKER=docker run $(USER) --rm --mount type=bind,src=$$(pwd),dst=/project/ $(CONTAINER) bash

TSX?=

LARGE=../tsortFile
SMALL=../tsortShort
all: build/main build/obj.dump


build/main: 
	$(DOCKER) -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" TSX="$(TSX)" -f build.Makefile'

.PHONY: build/obj.dump clean
build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/* res*.txt interpres*.txt mixedres*.txt

#.PRECIOUS: build/Monitor.interp% interp_time% build/Monitor.mixed% mixed_time% 
build/Monitor.interp% interp_time%:
ifeq ($(TSX), 1)
	$(DOCKER) -c 'cd /project/build/ && { time ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) 2>1 ; } 2> ../interp_time$*'
else
	$(DOCKER) -c 'cd /project/build/ && { time ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) 2>1 ; } 2> ../interp_time$*'
endif

build/Monitor.mixed% mixed_time%:
ifeq ($(TSX), 1)
	$(DOCKER) -c 'cd /project/build/ && { time ./run.sh -dontFork -taseManager=false -modelDebug -log=$(notdir $@) - $(LARGE) 2>1 ; } 2> ../mixed_time$*'
else
	$(DOCKER) -c 'cd /project/build/ && { time ./run.sh -dontFork -taseManager=false -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(LARGE) 2>1 ; } 2> ../mixed_time$*'
endif

interpres%.txt: build/Monitor.interp%
	grep ^OUT $< | awk '{print $$2}' > $@

mixedres%.txt: build/Monitor.mixed%
	grep ^OUT $< | awk '{print $$2}' > $@


tsortShort:
	head -n 10000 tsortFile > tsortShort


ref.txt:
	tsort tsortFile > ref.txt


shortref.txt: tsortShort
	tsort tsortShort > shortref.txt


.PHONY: resx5.txt
resx5.txt: cleanres res_1.txt res_2.txt res_3.txt res_4.txt res_5.txt
	echo "tsort:" > resx5.txt
	cat res_*.txt >> resx5.txt

.PHONY: res.txt
res.txt: cleanres res_1.txt
	echo "tsort:" > res.txt
	cat res_*.txt >> res.txt

.PHONY: cleanres
cleanres:
	rm -f res*.txt


res_%.txt: ref.txt shortref.txt interpres%.txt mixedres%.txt
	echo "  rep$*:" >> $@
	diff -q shortref.txt interpres$*.txt &>/dev/null; x=$$?; if [ $$x -ne 0 ]; then echo "    interp: FAIL"; else echo "    interp: PASS"; fi >> $@
	diff -q ref.txt mixedres$*.txt &>/dev/null; y=$$?; if [ $$y -ne 0 ]; then echo "    mixed: FAIL, $$(grep user mixed_time$* | awk '{print $$2}')"; else echo "    mixed: PASS, $$(grep user mixed_time$* | awk '{print $$2}')"; fi >> $@
