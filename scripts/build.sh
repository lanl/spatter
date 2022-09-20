#!/bin/bash

source ./scripts/config.sh

cd ${HOMEDIR}
source ${MODULEFILE}

git clone git@github.com:JDTruj2018/spatter.git
cd spatter
git checkout lanl-scaling

./configure/configure_omp_mpi_intel

cd build_omp_mpi_intel
make -j

