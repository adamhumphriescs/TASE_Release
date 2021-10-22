TARGET=md5sum

all:
	docker run --user $$(id -u $$USER):$$(id -g $$USER) --rm --mount type=bind,src=$$(pwd),dst=/TASE/test_build/project/ tase bash -c 'cd /TASE/test_build/ && TARGET=$(TARGET) make'  


clean:
	rm -rf build/*
	rm -f $(TARGET)* $(TARGET)* run_$(TARGET).sh Monitor
        rm -rf tmp/
        rm src/*.o
