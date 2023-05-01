# spatter

## Name
Spatter Scaling Experiments

## Description
This repository contains a few scripts and gather/scatter patterns of LANL codes in the form of Spatter JSON input files:

1. Build Spatter with MPI support for scaling experiments.
2. Performing on-node weak scaling experiments with Spatter given patterns from LANL codes

## Usage

### Dependencies
- CMake
- MPI
- C/C++ Compiler
- Python 3 (+matplotlib +pandas)

### Clone
```
git clone --recursive git@github.com:lanl/spatter.git
cd spatter
```

### Setup
The setup script will initialize your configuration file (`scripts/config.sh`) with CTS-1 defaults, and will build Spatter with GCC and MPI for the CPU. See the [Spatter documentation](https://github.com/hpcgarage/spatter) and other build scripts (`scripts/build_cpu.sh` and `scripts/build_cuda.sh`) for further instructions for building with different compilers or for GPUs.

```
bash scripts/setup.sh
```

This setup script performs the following:

1. Untars the Pattern JSON files located in the `patterns` directory
    - `patterns/flag/static_2d/001.fp.json`
    - `patterns/flag/static_2d/001.nonfp.json`
    - `patterns/flag/static_2d/001.json` 
    - `patterns/xrage/asteroid/spatter.json`
2. Generates a default module file located in `modules/custom.mod`
    - Contains generic module load statements for cmake, openmpi, and gcc
3. Populates the configuration file (`scripts/config.sh`) with reasonable defaults for a CTS-1 system
   - HOMEDIR is set to the directory this repository sits in
   - MODULEFILE is set to `modules/custom.mod`
   - SPATTER is set to path of the Spatter executable
   - ranklist is set to sweep from 1-36 threads/ranks respectively for a CTS-1 type system
   - boundarylist is set to reasonable defaults for scaling experiments (specifies the maximum value of a pattern index, limiting the size of the data array)
   - (STRONG SCALING ONLY) sizelist is set to reasonable defaults for strong scaling experiments (specifies the size of the pattern to truncate at)
4. Attempts to build Spatter with CMake, GCC, and MPI
   - You will need GCC and MPI loaded into your environment (include them in your `modules/custom.mod`)

### Running a Scaling Experiment
This will perform a weak scaling experiment 

The `scripts/scaling.sh` script has the following options:
- a: Application name
- p: Problem name
- f: Pattern name
- n: User-defined run name (for saving results)
- b: Boundary limit (option, default: off for weak scaling, on for strong scaling)
- c: Core binding (optional, default: off)
- g: Plotting/Post-processing (optional, default: on)
- r: Toggle MPI scaling (optional, default: off)
- w: Toggle Weak/Strong Scaling (optional, default: off = strong scaling)
- h: Print usage message

The Application name, Problem name, and Pattern name each correspond to subdirectories in this repository containing patterns stored as Spatter JSON input files.

Current options for Application name, Problem name, and Pattern name are listed below:
- Application name: flag, xrage
- Problem name: static_2d, asteroid
- Pattern name: 001 (for flag only), 001.fp (for flag only), 001.nonfp (for flag only), or spatter (for xrage only)


If MPI scaling is enabled, full bandwidth results will be stored in the `mpi_\<ranks\>r_1t.txt` files. Additionally, the \<rank\>r subdirectories hold sorted bandwidth data for each rank from each pattern that was found in the Spatter JSON input file. These files will be labeled `\<ranks\>r/\<ranks\>r_1t_\<pattern_num\>p.txt`.


#### Examples

Weak-Scaling experiment with core-binding turned on and plotting enabled. Boundary limiting will be disabled by default. Results will be found in `spatter.weakscaling/CTS1/flag/static_2d/001` and Figures will be found in 'figures/CTS1/flag/static_2d/001`.

```
bash scripts/scaling.sh -a flag -p static_2d -f 001 -n CTS1 -c -r -w

```

Strong-Scaling experiment with plotting enabled. Boundary limiting using the values in boundarylist will be enabled by default. Results will be found in `spatter.strongscaling/A100/flag/static_2d/001` and Figures will be found in `figures/CTS1/flag/static_2d/001`.
```
bash scripts/scaling.sh -a flag -p static_2d -f 001 -n A100 -r 
```

The `scripts/mpirunscaling.sh` script has been provided if you need to use `mpirun` to launch jobs rather than `srun`.

### Running Spatter Serially
Simply update the `ranklist` variables in `scripts/config.sh` to the value of `( 1 )`

```
bash scripts/scaling.sh -a flag -p static_2d -f 001 -n A100 -r
```


## Customizing

### Editing the Module Environment

Add your module load statements or path variables to the `modules/custom.mod` file. This file is loaded prior to performing any scaling experiments.

For plotting (see `scripts/plot_mpi.py`), you will need a Python 3 installation with matplotlib and pandas

For CPU builds, you need CMake, an GNU or Intel compiler, and MPI at a minimum
For GPU builds (CUDA), you need CMake, nvcc, gcc, and MPI

#### Copy an existing Module Environment File
For a base CPU Module file:
`cp modules/darwin_skylake.mod modules/<name>.mod`

For a base GPU Module file:
`cp modules/darwin_a100.mod modules/<name>.mod`

Edit the modules required on your system
### Editing the Configuration
Edit the configuration bash script
`vim scripts/config.sh`

- Change the HOMEDIR to the path to the root of this repository (absolute path).
- Change the MODULEFILE to your new module file (absolute path).
- You may leave SPATTER unchanged unless you have another Spatter binary on your system. If so, you may update this variable to point to you Spatter binary.
- Change ranklist as appropriate for your system. This sets the number of MPI ranks Spatter will scale through.
- Change the boundarylist as appropriate for scaling experiments. This defines the largest index that can exist in the pattern array. Any indices larger will be truncated by x % boundary. This in turn, limits the size of the data array, since it has extent max(pattern). Only change if you know what you are doing.
- (STRONG SCALING ONLY) Change sizelist as appropriate for strong scaling experiments. This defines the pattern length to truncate at as we scale. The defaults provided should work for the provided patterns. Only change if you know what you are doing.

### Building Spatter

See the main [Spatter](https://github.com/hpcgarage/spatter) repository for more in depth instructions. We have included a few basic scripts to get you started. Modify as needed.

#### Building Spatter on CPUs
```
bash scripts/build_cpu.sh
```

#### Building Spatter on NVIDIA GPUs
```
bash scripts/builds_cuda.sh
```


## Support
jereddt@lanl.gov

## Authors and acknowledgment
jereddt@lanl.gov
kss@lanl.gov
gshipman@lanl.gov

## License
BSD-3 License
