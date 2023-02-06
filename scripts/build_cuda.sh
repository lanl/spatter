#!/bin/bash

echo ${HOMEDIR}
source ${HOMEDIR}/scripts/config.sh

cd ${HOMEDIR}
source ${MODULEFILE}

git clone git@github.com:hpcgarage/spatter.git
cd spatter

cc=`nvidia-smi --query-gpu=compute_cap --format=csv,noheader|head -n 1 | tr -d '.'`

./configure/configure_cuda ${cc}

cd build_cuda
make -j

