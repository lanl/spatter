#!/bin/bash

source ./scripts/config.sh

cd ${HOMEDIR}
source ${MODULEFILE}

git@github.com:hpcgarage/spatter.git
cd spatter

./configure/configure_omp_mpi_intel

cd build_omp_mpi_intel
make -j

