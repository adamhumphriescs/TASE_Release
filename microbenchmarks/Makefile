all: collect

collect: concrete/results.txt slidingscale/bigNum/SlidingScaleResults.txt
	mv concrete/results.txt ConcreteResults.txt
	mv slidingscale/bigNum/SlidingScaleResults.txt SlidingScaleResults.txt

concrete/results.txt:
	$(MAKE) -C concrete

slidingscale/bigNum/SlidingScaleResults.txt:
	$(MAKE) -C slidingscale/bigNum/
	$(MAKE) -j4 -C slidingscale/bigNum/ SlidingScaleResults.txt


clean:
	$(MAKE) -C concrete clean
	$(MAKE) -C slidingscale/bigNum clean
