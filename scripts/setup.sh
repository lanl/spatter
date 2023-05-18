#!/bin/bash

export HOMEDIR=`pwd`

echo "Generating Base Module Files"
cp modules/darwin_skylake.mod modules/cpu.mod
cp modules/darwin_a100.mod modules/gpu.mod

echo "Pulling LFS files..."
git lfs pull
echo""

echo "Untarring Patterns..."
find ./patterns/flag -iname '*.tar.gz' -exec tar -xvzf {} \;
find ./patterns/xrage -iname '*.tar.gz' -exec tar -xvzf {} \;
mv spatter.json patterns/xrage/asteroid/spatter.json
echo ""

echo "Configuring scripts/cpu_config.sh"
sed -i "s|HOMEDIR=.*|HOMEDIR=$HOMEDIR|g" scripts/cpu_config.sh
sed -i "s|MODULEFILE=.*|MODULEFILE=$HOMEDIR\/modules\/cpu.mod|g" scripts/cpu_config.sh
sed -i "s|SPATTER=.*|SPATTER=$HOMEDIR\/spatter\/build_omp_mpi_gnu\/spatter|g" scripts/cpu_config.sh

sed -i "s|ranklist=.*|ranklist=\( 1 2 4 8 16 18 32 36 \)|g" scripts/cpu_config.sh
sed -i "s|boundarylist=.*|boundarylist=\( 81920 40960 20480 10240 5120 4550 2560 2275 \)|g" scripts/cpu_config.sh
sed -i "s|sizelist=.*|sizelist=\( 16384 8192 4096 2048 1024 910 512 455 \)|g" scripts/cpu_config.sh
echo ""

echo "Configuring scripts/gpu_config.sh"
sed -i "s|HOMEDIR=.*|HOMEDIR=$HOMEDIR|g" scripts/gpu_config.sh
sed -i "s|MODULEFILE=.*|MODULEFILE=$HOMEDIR\/modules\/gpu.mod|g" scripts/gpu_config.sh
sed -i "s|SPATTER=.*|SPATTER=$HOMEDIR\/spatter\/build_cuda\/spatter|g" scripts/gpu_config.sh

sed -i "s|ranklist=.*|ranklist=\( 1 1 1 1 1 1 1 1 \)|g" scripts/gpu_config.sh
sed -i "s|boundarylist=.*|boundarylist=\( 81920 40960 20480 10240 5120 4550 2560 2275 \)|g" scripts/gpu_config.sh
sed -i "s|sizelist=.*|sizelist=\( 16384 8192 4096 2048 1024 512 256 128 \)|g" scripts/gpu_config.sh
echo ""
