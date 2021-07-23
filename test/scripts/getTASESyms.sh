set -e

#This script takes an input object file or archive (untested)
#and project name, and outputs a list of the functions that TASE
#needs to make interpretation IR for.

Input=$1
ProjName=$2



nm --defined-only $Input | grep -i " t " | cut -d' ' -f 3 > $ProjName.tase
