ROOT?=/project
BIN?=main
CFLAGS?=-O0
USER=--user $$(id -u):$$(id -g)
CONTAINER?=tasetest
DOCKER=docker run $(USER) --rm --mount type=bind,src=$$(pwd),dst=/project/ $(CONTAINER) bash 

TSX?=

LARGE=../GutenburgDictionary.txt
SMALL=../harness.c
all: build/main build/obj.dump

build/main: 
	$(DOCKER) -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" TSX="$(TSX)" -f build.Makefile'

.PHONY: build/obj.dump clean
build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/* res*.txt interpres*.txt mixedres*.txt

#.PRECIOUS: build/Monitor.interp% build/Monitor.mixed%
build/Monitor.interp% interp_time%:
ifeq ($(TSX), 1)
	bash -c 'cd build/ && { time ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) 2>1 ; } 2> ../interp_time$*'
else
	bash -c 'cd build/ && { time ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) 2>1 ; } 2> ../interp_time$*'
endif

build/Monitor.mixed% mixed_time%:
ifeq ($(TSX), 1)
	bash -c 'cd build/ && { time ./run.sh -dontFork -taseManager=false -check-overshift=false -modelDebug  -log=$(notdir $@) - $(LARGE) 2>1 ; } 2> ../mixed_time$*'
else
	bash -c 'cd build/ && { time ./run.sh -dontFork -taseManager=false -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(LARGE) 2>1 ; } 2> ../mixed_time$*'
endif

mixedres%.txt: build/Monitor.mixed%
	x=$$(grep -c model_printf $<); if [ $$x -gt 0 ]; then grep -A2 model_printf $< | tail -n 1 > $@; else grep -A1 model_puts $< | tail -n1 > $@; fi


interpres%.txt: build/Monitor.interp%
	x=$$(grep -c model_printf $<); if [ $$x -gt 0 ]; then grep -A2 model_printf $< | tail -n 1 > $@; else grep -A1 model_puts $< | tail -n1 > $@; fi

ref.txt:
	cd build/ && sha256sum $(LARGE) | awk '{print $$1}' > ../ref.txt

shortref.txt:
	cd build && sha256sum $(SMALL) | awk '{print $$1}' > ../shortref.txt


.PHONY: resx5.txt
resx5.txt: cleanres res_1.txt res_2.txt res_3.txt res_4.txt res_5.txt
	echo "sha256sum:" > resx5.txt
	cat res_*.txt >> resx5.txt

.PHONY: res.txt
res.txt: cleanres res_1.txt
	echo "sha256sum:" > res.txt
	cat res_*.txt >> res.txt

.PHONY: cleanres
cleanres:
	rm -f res*.txt


res_%.txt: ref.txt shortref.txt  interpres%.txt mixedres%.txt
	echo "  rep$*:" >> $@
	diff -q shortref.txt interpres$*.txt &>/dev/null; x=$$?; if [ $$x -ne 0 ]; then echo "    interp: FAIL"; else echo "    interp: PASS"; fi >> $@
	diff -q ref.txt mixedres$*.txt &>/dev/null; y=$$?; if [ $$y -ne 0 ]; then echo "    mixed: FAIL, $$(grep user mixed_time$* | awk '{print $$2}')"; else echo "    mixed: PASS, $$(grep user mixed_time$* | awk '{print $$2}')"; fi >> $@
