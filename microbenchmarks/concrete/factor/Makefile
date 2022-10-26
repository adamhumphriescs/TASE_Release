ROOT?=/project
BIN?=main
SMALL=5413218152718641574491217
LARGE=16895424309675413218152718641574491217
CFLAGS?=-O0

all: build/main build/obj.dump


build/main: 
	docker run --user $$(id -u):$$(id -g) --rm --mount type=bind,src=$$(pwd),dst=/project/ tase bash -c 'cd $(ROOT) && make CFLAGS="$(CFLAGS)" -f build.Makefile'

.PHONY: test gdbtest smalltest mixedtest objdump clean
test:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - $(SMALL)


gdbtest:
	cd build/ && env KLEE_RUNTIME_LIBRARY_PATH=$$(pwd)/bitcode/ gdb --args main -project=main -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - $(SMALL)

mixedtest:
	cd build/ && rm -f Monitor* && ./run.sh -taseDebug -modelDebug -dontFork -taseManager=false -singleStepping -check-overshift=false - $(LARGE)

build/obj.dump: build/main
	objdump -C -D -w -M suffix -j .text build/main > build/obj.dump

longtest:
	cd build/ && rm -f Monitor* && nohup ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false - $(LARGE) &

clean:
	rm -rf build/* res*.txt interpres*.txt mixedres*.txt


build/Monitor.interp% interp_time%:
	cd build/ && time( ./run.sh -dontFork -taseManager=false -execMode=INTERP_ONLY -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) ) > interp_time$*


build/Monitor.mixed% mixed_time%:
	cd build/ && $( ./run.sh -dontFork -taseManager=false -singleStepping -check-overshift=false -modelDebug -log=$(notdir $@) - $(SMALL) ) > mixed_time$*


mixedres%.txt: build/Monitor.mixed%
	grep $(SMALL) $< | tail -n1 > $@


interpres%.txt: build/Monitor.interp%
	grep $(SMALL) $< | tail -n1 | sed 's/.*"//g' > $@


ref.txt:
	factor $(SMALL) > ref.txt

.PHONY: resx5.txt
resx5.txt: cleanres res_1.txt res_2.txt res_3.txt res_4.txt res_5.txt
	echo "factor:" > resx5.txt
	cat res_*.txt >> resx5.txt

.PHONY: res.txt
res.txt: cleanres res_1.txt
	echo "factor:" > res.txt
	cat res_*.txt >> res.txt

.PHONY: cleanres
cleanres:
	rm -f res*.txt


res_%.txt: ref.txt mixedres%.txt interpres%.txt
	echo "  rep$*:" >> $@
	diff -q ref.txt interpres$*.txt; x=$$?; if [ $$x -ne 0 ]; then echo "    interp: FAIL, $$(cat interp_time$*)"; else echo "    interp: PASS, $$(cat interp_time$*)"; fi >> $@
	diff -q ref.txt mixedres$*.txt; y=$$?; if [ $$y -ne 0 ]; then echo "    mixed: FAIL, $$(cat mixed_time$*)"; else echo "    mixed: PASS, $$(cat mixed_time$*)"; fi >> $@
