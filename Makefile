SHELL=/bin/bash
TARGET?=tase
DIR?=

all: docker


objdump:
	git clone git://sourceware.org/git/binutils-gdb.git
	cd binutils-gdb/ && git checkout 20756b0fbe065a84710aa38f2457563b57546440
	cp objdump.c binutils-gdb/binutils/
	cp section.c bfd.h binutils-gdb/bfd/
	cd binutils-gdb && ./configure
	make -C binutils-gdb/
	cp binutils-gdb/binutils/objdump .
	rm -rf binutils-gdb

.phony: tase_llvm_base
tase_llvm_base:
	docker build --network=host --no-cache --target tase_llvm -t tase_llvm_base .

.tase_llvm_id:
	docker run -it --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --name tase_llvm_build -d tase_llvm_base > .tase_llvm_id

tase_llvm: .tase_llvm_id objdump
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/ && cp -r test/tase/include/tase/* /TASE/include/tase'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/ && cp -r test/other/* /TASE/include/traps/'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/ && cp -r test/tase/tase_link.ld /TASE/'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/ && cp -r test/scripts/* /TASE/scripts/'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/ && cp objdump /'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/parseltongue86/ && ./setup.sh && cp -r . /TASE/parseltongue86/'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/install/ && make -j 16 tase_clang'
	docker tag $$(docker commit tase_llvm_build | awk '{split($$0, m, /:/); print m[2]}') tase_llvm
	docker stop tase_llvm_build
	docker rm tase_llvm_build
	rm -f .tase_llvm_id

.tase_id:
	docker run -it --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --name tase_build -d tase_llvm > .tase_id


docker: .tase_id
#	nohup docker build --network=host -t tase . 2>&1 > err.txt &
	docker exec tase_build bash -c 'cd /TASE_BUILD/install && make -j 16 setup && cd / && cp -r /TASE_BUILD/install/ /TASE/ && apt-get autoremove'
	docker tag $$(docker commit tase_build | awk '{split($$0, m, /:/); print m[2]}') tase
	docker stop tase_build
	docker rm tase_build
	rm -f .tase_id


directory:
	mkdir -p $(DIR)/llvm-3.4.2
	curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C $(DIR)/llvm-3.4.2 --strip 1
	mkdir -p $(DIR)/include/ $(DIR)/scripts/
	cp -r $$(pwd)/test/tase/include/tase/ $(DIR)/include/tase/
	cp -r $$(pwd)/test/other/ $(DIR)/include/traps/
	cp -r $$(pwd)/openssl/include/ $(DIR)/include/openssl/
	cp $$(pwd)/test/tase/tase_link.ld $(DIR)/
	cp -r $$(pwd)/test/scripts/ $(DIR)/scripts/
	env BUILD_DIR=$$(pwd) RUN_DIR=$(DIR) $(MAKE) -C install setup
	mkdir -p $(DIR)/install
	cp -r $$(pwd)/install/* $(DIR)/install/


klee-update:
	cd klee && git status --porcelain | awk '$$1=="M"{print $$2}' > ../klee_changes.txt
	while read line; do cp klee/$$line ../TASE_KLEE/$$line; done < klee_changes.txt
	make -C ../TASE_KLEE/
	git submodule update --remote --force klee
	git add klee
	git commit -m 'updated klee'
	git push
