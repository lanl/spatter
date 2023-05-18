#!/bin/bash

source ./scripts/cpu_config.sh

cd ${HOMEDIR}
source ${MODULEFILE}

cd spatter

./configure/configure_omp_mpi_gnu

cd build_omp_mpi_gnu
make -j

