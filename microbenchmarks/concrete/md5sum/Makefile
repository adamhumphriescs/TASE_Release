ROOT?=/project
BIN?=main
CFLAGS?=-O0

all: build/main build/obj.dump


build/main: 
	docker run --user $$(id -u):$$(id -g) --rm --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'

test:
	cd build/ && rm -f Monitor* && cp ../GutenburgDictionary.txt . && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false


mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false  - ../harness.c

build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

clean:
	rm -rf build/* res*.txt interpres*.txt mixedres*.txt


build/Monitor.interp%:
	cd build/ && ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY  -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - ../harness.c

build/Monitor.mixed%:
	cd build/ && ./run.sh -dontFork -taseManager=false -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - ../harness.c


mixedres%.txt: build/Monitor.mixed%
	x=$$(grep -c model_printf $<); if [ $$x -gt 0 ]; then grep -A2 _printf $< | tail -n1 > $@; else grep -A1 _puts $< | tail -n1 > $@; fi

interpres%.txt: build/Monitor.interp%
	x=$$(grep -c model_printf $<); if [ $$x -gt 0 ]; then grep -A2 _printf $< | tail -n1 > $@; else grep -A1 _puts $< | tail -n1 > $@; fi

ref.txt:
	cd build/ && md5sum ../harness.c | awk '{print $$1}' > ../ref.txt

.PHONY: resx5.txt
resx5.txt: cleanres res_1.txt res_2.txt res_3.txt res_4.txt res_5.txt
	echo "md5sum:" > resx5.txt
	cat res_*.txt >> resx5.txt

.PHONY: res.txt
res.txt: cleanres res_1.txt
	echo "md5sum:" > res.txt
	cat res_*.txt >> res.txt

.PHONY: cleanres
cleanres:
	rm -f res*.txt



res_%.txt: ref.txt interpres%.txt mixedres%.txt
	echo "  rep$*:" >> $@
	diff -q ref.txt interpres$*.txt; x=$$?; if [ $$x -ne 0 ]; then echo "    interp: FAIL"; else echo "    interp: PASS"; fi >> $@
	diff -q ref.txt mixedres$*.txt; y=$$?; if [ $$y -ne 0 ]; then echo "    mixed: FAIL"; else echo "    mixed: PASS"; fi >> $@
