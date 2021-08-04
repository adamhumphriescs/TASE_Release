
#Given a project name, setup a directory and subdirectories for it.
set -e
source ~/.bashrc

PROJ_NAME=$1

#Check to see if the directory already exists.
PROJ_PATH=$TASE_ROOT_DIR/projects/$PROJ_NAME

if [ -d "$PROJ_PATH" ]; then
    echo "ERROR: Project already exists with name " $PROJ_NAME "."
    echo "Delete the entire folder at " $PROJ_PATH " if you wish to create a new \
project with name " $PROJ_NAME
    exit 1
fi

mkdir $PROJ_PATH
mkdir $PROJ_PATH/src
mkdir $PROJ_PATH/build
mkdir $PROJ_PATH/build/bitcode
mkdir $PROJ_PATH/build/obj

cp ./utils/harness.c $PROJ_PATH/src/
cp ./utils/build.sh $PROJ_PATH/
cp ./utils/make_byte_symbolic.c $PROJ_PATH/src/
