TARGET?=tase
DIR?=

docker:
	nohup docker build --network=host -t $(TARGET) . 2>&1 > err.txt &

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
