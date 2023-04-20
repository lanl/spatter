#!/bin/bash

HOMEDIR=./spatter/
#MODULEFILE=${HOMEDIR}/modules/darwin_h100.mod
MODULEFILE=${HOMEDIR}/modules/darwin_skylake.mod

#SPATTER=./spatter/build_omp_mpi_intel/spatter
SPATTER=./spatter/build_omp_mpi_intel/spatter

threadlist=( 1 2 4 8 16 22 32 44 64 88 )
ranklist=( 1 2 4 8 16 22 32 44 64 88 )
sizelist=( 1024 512 256 128 64 46 32 23 16 8 )

#threadlist=( 1 2 4 8 16 32 56 64 112 128 224 )
#ranklist=( 1 2 4 8 16 32 56 64 112 128 224 )

#threadlist=( 1 )
#ranklist=( 1 )
