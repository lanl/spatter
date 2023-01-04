# spatter

## Name
Spatter Weak Scaling Experiments

## Description
This repository contains a few scripts and gather/scatter patterns of LANL codes in the form of Spatter JSON input files:

1. Build Spatter with MPI support for weak scaling experiments. See the lanl-scaling branch of (https://github.com/JDTruj2018/spatter/tree/lanl-scaling/configure) until the changes are merged in
2. Performing on-node weak scaling experiments with Spatter given patterns from LANL codes
	a. MPI
	b. OpenMP (In Progress)

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Usage
### Create a Module Environment
Copy the current Darwin Module Environment File
`cp modules/darwin.mod modules/<name>.mod`

Edit the modules required on your system
You need CMake, an Intel Compiler, and MPI at a minimum

### Editing the Configuration
Edit the configuration bash script
`vim scripts/config.sh`

Change the HOMEDIR to the path to the root of this repository.
Change the MODULEFILE to your new module file.
Change threadlist and ranklist as appropriate for your system. This sets the number of OpenMP threads or MPI ranks Spatter will scale through
You may leave SPATTER unchanged unless you have another Spatter binary on your system. If so, you may update this variable to point to you Spatter binary. Otherwise, we will build Spatter in the next step.

### Building Spatter
```
cd spatter
bash scripts/builds.sh
```

### Running a Scaling Experiment
This will perform a weak scaling experiment 

The `scripts/scaling.sh` script has the following options:
	a: Application name
	p: Problem name
	f: Pattern name
	n: Architecture/Partition
	c: Core binding (optional, default: off)
        g: Plotting/Post-processing (optional, default: on)
	r: Toggle MPI scaling (optional, default: off)
	t: Toggle OpenMP scaling (optional, default: off)
	h: Print usage message

The Application name, Problem name, and Pattern name each correspond to subdirectories in this repository containing patterns stored as Spatter JSON input files.
The JSON file of interest should be located at <Arch>/<Application>/<Problem>/<Pattern>.json

The results of the weak scaling experiment will be stored in the spatter.scaling directory, within the <Arch>/<Application>/<Problem>/<Pattern> subdirectory.

If MPI scaling is enabled, full bandwidth results will be stored in the mpi_<ranks>r)1t.txt files. Additionally, the <rank>r subdirectories hold sorted bandwidth data for each rank from each pattern that was found in the Spatter JSON input file. These files will be labeled <ranks>r/<ranks>r_1t_<pattern_num>p.txt.

If OpenMP threading is turned on, full bandwidth results will be stored in the openmp_1r_<threads>t.txt files.

```
cd spatter
bash scripts/scaling.sh -a flag -p static_2d -f 001 -n spr -r
```

### Running Spatter Serially
Simply update the `threadlist` and `ranklist` variables in `scripts/config.sh` to the value of `( 1 )`

```
bash scripts/scaling.sh -a flag -p static_2d -f 001 -n spr -r
```

## Support
jereddt@lanl.gov

## Authors and acknowledgment
jereddt@lanl.gov
kss@lanl.gov
gshipman@lanl.gov

## License
BSD-3 License
