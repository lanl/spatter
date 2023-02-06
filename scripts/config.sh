#!/bin/bash

HOMEDIR=/scratch/users/jereddt/NVIDIA/spatter/
MODULEFILE=${HOMEDIR}/modules/darwin_a100.mod

SPATTER=${HOMEDIR}/spatter/build_cuda/spatter

#threadlist=( 1 2 4 8 16 22 32 44 64 88 )
#ranklist=( 1 2 4 8 16 22 32 44 64 88 )

#threadlist=( 1 2 4 8 16 32 56 64 112 128 224 )
#ranklist=( 1 2 4 8 16 32 56 64 112 128 224 )

threadlist=( 1 )
ranklist=( 1 2 )
