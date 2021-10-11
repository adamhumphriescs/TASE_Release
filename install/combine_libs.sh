#!/bin/bash -e

outlib="$1"
libs=""
dirs=""
objs=""

for arg in "${@:2}"
do
    if echo "$arg" | egrep -q '[a-zA-Z0-9_/]+\.a'
    then
	dd=$(basename "$arg" .a)
	mkdir -p "$dd"
	pushd "$dd"
	ar x "$arg"
	popd
	libs="$(pwd)/$dd/*.o $libs"
	dirs="$dd $dirs"
    else
	objs="$arg $objs"
    fi
done

echo "Combining libs:"
echo "$libs"
echo "and objects:"
echo "$objs"
echo "into"
echo "$1"

ar crs $outlib $objs $libs
rm -rf $dirs
