set -e

./build_heartbleed.sh

cp ./traces/heartbleed/heartbleed_simple_stream01.ktest     ssl.ktest
cp ./traces/heartbleed/heartbleed_simple_stream01.ktest.key ssl.mastersecret

eval `cat vercmd`
