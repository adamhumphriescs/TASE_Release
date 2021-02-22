## Setup

This code was tested on Python 3.6 using the modules in the requirements.txt file.

Please see the Makefile and run `make init` to install all the pip modules needed.

## Running tests and main application

This is default make target or `make test` if you prefer.  This will lint and test
the library.

A top-level "parseltongue.py" currently launches the program.
`make run` will launch that.
TODO: Have make install put a symlink to that in install_root or something.
