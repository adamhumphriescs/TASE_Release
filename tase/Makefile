SRC=$(BUILD_DIR)/tase/
DST=$(BUILD_DIR)/build/tase/

TASE_OBJSA=$(addprefix $(DST)/springboard/,$(basename $(wildcard $(SRC)/springboard/*.c) $(wildcard $(SRC)/springboard/*.S)))

TASE_OBJSB=$(addprefix $(DST)/,$(basename $(wildcard $(SRC)/*.c)))

TASE_SHIMOBJS=$(addprefix $(DST)/traps/,$(basename $(wildcard $(SRC)/traps/*.c)))

TASE_OBJS=$(TASE_OBJSA) $(TASE_OBJSB) $(TASE_SHIMOBJS) $(SFLOAT_OBJS)

SFLOAT_OBJS=$(addprefix $(DST)/compiler-rt_soft_float/,$(addsuffix .o,$(basename $(wildcard $(SRC)compiler-rt_soft_float/*.c))))


all: $(RUN_DIR)/lib/libtase.a $(TASE_LINK)

$(TASE_LINK):
	cp $(BUILD_DIR)/tase/tase_link.ld $(RUN_DIR)/tase_link.ld

$(RUN_DIR)/lib/libtase.a: $(TASE_OBJS)
	ar crs $(RUN_DIR)/lib/libtase.a $(TASE_OBJS)

$(DST)/traps/%.o: $(SRC)/traps/%.c $(SRC)/traps/%.S
	$(TASE_CLANG) -fPIC -c -O1 -DTASE_TSX -DTASE_ENABLE=1 -I$(BUILD_DIR)/test/tase/include/  $(MODELED_FN_ARG) $< -o $@

$(DST)/%.o: $(SRC)/%.c
	$(CLANG) -fPIC -c -O1 -I$(BUILD_DIR)/test/tase/include/ $< -o $@

$(DST)/traps/%.o: $(SRC)/traps/%.c
	$(TASE_CLANG) -fPIC -c -O0 $(NO_FLOAT_ARG) $(MODELED_FN_ARG) $< -o $@

$(DST)/compiler-rt_soft_float/%.o: $(SRC)/compiler-rt_soft_float/%.c
	$(CLANG) -c $< -o $@
