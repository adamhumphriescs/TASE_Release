This directory contains a synthetic microbenchmark based on BigNum addition.

The purpose of the benchmark is to measure the impact of gradually increasing
the amount of symbolic computation required for a fixed size workload (e.g., adding two
50,000 byte integers together).

In order to isolate the costs of doing concrete and symbolic calculations, the benchmark
should not cause a symbolic execution tool to encounter any branches dependent on symbolic data.
The idea is that encountering branches dependent on symbolic data introduces additional costs
for a symbolic execution tool including constraint solving and path management.

More details are available in the TASE paper.
