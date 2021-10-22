all:
	nohup docker build --network=host -t tase . 2>&1 > err.txt &

.PHONY: test
test:
	nohup docker build --network=host -t tase_intermediate . 2>&1 > err.txt &
