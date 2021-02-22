set -e
#Build a dummy project from the cksum source so that TASE will pass
#the initial build.

mkdir -p ../build_klee/lib

pushd microbenchmarks/concrete/cksum
./makeproj.sh
popd
