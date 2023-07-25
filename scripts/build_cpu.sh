#!/bin/bash

echo ${HOMEDIR}
source ${HOMEDIR}/scripts/cpu_config.sh

cd ${HOMEDIR}
source ${MODULEFILE}

cd spatter

cmake -DBACKEND=openmp -DCOMPILER=gnu -DUSE_MPI=1 -B build_omp_gnu_mpi -S .

cd build_omp_mpi_gnu
make -j

