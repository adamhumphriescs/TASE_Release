TARGET=md5sum

all:
	docker run --user $$(id -u $$USER):$$(id -g $$USER) --rm --mount type=bind,src=$$(pwd),dst=/TASE/install/project/ tase2 bash -c 'cd /TASE/install/ && TARGET=$(TARGET) make'  


clean:
	rm -rf build/*
	rm -f $(TARGET)* $(TARGET)* run_$(TARGET).sh
	rm -rf tmp/
	rm -f src/*.o
	rm -f Monitor*
	rm -f cartridge_info.txt
