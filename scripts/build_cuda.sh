#!/bin/bash

echo ${HOMEDIR}
source ${HOMEDIR}/scripts/gpu_config.sh

cd ${HOMEDIR}
source ${MODULEFILE}

cd spatter

cc=`nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -n 1 | tr -d '.'`

cmake -DBACKEND=cuda -DCOMPILER=nvcc -DCUDA_ARCH=${cc} -B build_cuda -S .

cd build_cuda
make -j

