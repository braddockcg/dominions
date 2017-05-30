#!/bin/bash
# At least a very basic sanity check on installation.
# We don't have a full unit test coverage. -bcg'17

(cd src/DOM141M && make)
./dominions.py install --version 141 /tmp/141
./dominions.py install --version 500 /tmp/500
./dominions.py install --version 2000 /tmp/2000

docker build --build-arg VERSION=141 -t dominions141 .
docker build --build-arg VERSION=500 -t dominions500 .
docker build --build-arg VERSION=2000 -t dominions2000 .

