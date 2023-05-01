#!/bin/bash

export HOMEDIR=`pwd`

cp modules/darwin_skylake.mod modules/custom.mod

echo "Pulling LFS files..."
git lfs pull
echo""

echo "Untarring Patterns..."
find ./patterns/flag -iname '*.tar.gz' -exec tar -xvzf {} \;
find ./patterns/xrage -iname '*.tar.gz' -exec tar -xvzf {} \;
mv spatter.json patterns/xrage/asteroid/spatter.json
echo ""

echo "Configuring scripts/config.sh"
sed -i "s|HOMEDIR=.*|HOMEDIR=$HOMEDIR|g" scripts/config.sh
sed -i "s|MODULEFILE=.*|MODULEFILE=$HOMEDIR\/modules\/custom.mod|g" scripts/config.sh
sed -i "s|SPATTER=.*|SPATTER=$HOMEDIR\/spatter\/build_omp_mpi_gnu\/spatter|g" scripts/config.sh

sed -i "s|ranklist=.*|ranklist=\( 1 2 4 8 16 18 32 36 \)|g" scripts/config.sh
sed -i "s|boundarylist=.*|boundarylist=\( 81920 40960 20480 10240 5120 4550 2560 2275 \)|g" scripts/config.sh
sed -i "s|sizelist=.*|sizelist=\( 16384 8192 4096 2048 1024 910 512 455 \)|g" scripts/config.sh
echo ""

echo "Building Spatter..."
bash scripts/build_cpu.sh
