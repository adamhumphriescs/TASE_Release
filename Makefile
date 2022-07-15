SHELL=/bin/bash
TARGET?=tase
DIR?=

#all: tase_llvm_base update tase_llvm tase
all: update tase_llvm tase

.phony: update
update:
	git submodule update --init --jobs 7

.phony: tase_llvm_base
tase_llvm_base:
	docker build --network=host --no-cache --target tase_llvm -t tase_llvm_base .

.tase_llvm_id:
	docker run -it --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --name tase_llvm_build -d tase_llvm_base > .tase_llvm_id

# seperate command for the objdump move so we have root permissions...
tase_llvm: .tase_llvm_id
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/install/ && make -j 16 /objdump'
	docker exec tase_llvm_build bash -c 'cd /TASE_BUILD/install/ && make -j 16 tase_clang'
	docker tag $$(docker commit tase_llvm_build | awk '{split($$0, m, /:/); print m[2]}') tase_llvm
#	docker stop tase_llvm_build
#	docker rm tase_llvm_build
	rm -f .tase_llvm_id

.tase_id:
	docker run -it --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --name tase_build -d tase_llvm > .tase_id


tase: .tase_id
	docker exec tase_build bash -c 'cd /TASE_BUILD/install && make -j 16 setup && cd / && cp -r /TASE_BUILD/install/ /TASE/ && apt-get autoremove'
	docker tag $$(docker commit tase_build | awk '{split($$0, m, /:/); print m[2]}') tase
	docker stop tase_build
	docker rm tase_build
	rm -f .tase_id

# directory:
# 	mkdir -p $(DIR)/llvm-3.4.2
# 	curl -s https://releases.llvm.org/3.4.2/clang+llvm-3.4.2-x86_64-linux-gnu-ubuntu-14.04.xz | tar xJvf - -C $(DIR)/llvm-3.4.2 --strip 1
# 	mkdir -p $(DIR)/include/ $(DIR)/scripts/
# 	cp -r $$(pwd)/test/tase/include/tase/ $(DIR)/include/tase/
# 	cp -r $$(pwd)/test/other/ $(DIR)/include/traps/
# 	cp -r $$(pwd)/openssl/include/ $(DIR)/include/openssl/
# 	cp $$(pwd)/test/tase/tase_link.ld $(DIR)/
# 	cp -r $$(pwd)/test/scripts/ $(DIR)/scripts/
# 	env BUILD_DIR=$$(pwd) RUN_DIR=$(DIR) $(MAKE) -C install setup
# 	mkdir -p $(DIR)/install
# 	cp -r $$(pwd)/install/* $(DIR)/install/


klee-update:
	cd klee && git status --porcelain | awk '$$1=="M"{print $$2}' > ../klee_changes.txt
	while read line; do cp klee/$$line ../TASE_KLEE/$$line; done < klee_changes.txt
	rm klee_changes.txt
	make -C ../TASE_KLEE/update/
	git submodule update --remote --force klee
	git add klee
	git commit -m 'updated klee'
	git push

llvm-update:
	cd llvm && git status --porcelain | awk '$$1=="M"{print $$2}' > ../llvm_changes.txt
	while read line; do cp llvm/$$line ../llvm/$$line; done < llvm_changes.txt
	make -C ../llvm/update
	git submodule update --remote --force llvm
	git add llvm
	git commit -m 'updated llvm'
	git push

musl-update:
	cd musl && git status --porcelain | awk '$$1=="M"{print $$2}' > ../musl_changes.txt
	while read line; do cp musl/$$line ../TASE_musl/$$line; done < musl_changes.txt
	make -C ../TASE_musl/update
	git submodule update --remote --force musl
	git add musl
	git commit -m 'updated musl'
	git push

#llvm-dev-container:
#	docker run --mount type=bind,src=$$(pwd),dst=/TASE_BUILD/ --mount type=bind,src=$$(pwd)/llvm_test/,dst=/test/ --rm -it tase_llvm
