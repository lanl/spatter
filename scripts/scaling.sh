#!/bin/bash

usage() {
	echo "Usage ./scaling.sh -a <application> -p <input problem> -f <pattern> -n <arch> [-c 'toggle core binding'] [-g <0/1 enable/disable plotting>] [-r 'toggle scaling with MPI'] [-t 'toggle scaling with OpenMP']
		-a : Specify the name of the application (see available apps in the patterns sub-directory)
		-p : Specify the name of the input problem (see available problems in the application sub-directory)
		-f : Specify the base name of the input JSON file containing the gather/scatter pattern (see available patterns in the input problem subdirectory)
		-n : Specify the architecture/partition being ran on (used to appropriately save data)
		-c : Optional, toggle core binding (default: off)
		-g : Optional, toggle plotting/post-processing. Requires python3 environment with pandas, matplotlib (default: on)
		-r : Optional, enable scaling with MPI (default: off)
		-t : Optional, enable scaling with OpenMP (default: off)"	
}

if [ $# -lt 3 ] ; then
	usage
else
	MPI=0
	OPENMP=0
	PLOT=1
	BINDING=0
	while getopts "a:f:p:n:cgrt" opt; do
		case $opt in 
			a) APP=$OPTARG
			;;
			f) PATTERN=$OPTARG
			;;
			p) PROBLEM=$OPTARG
			;;
			n) ARCH=$OPTARG
			;;
			c) BINDING=1
			;;
			g) PLOT=$OPTARG
			;;
			r) MPI=1
			;;
			t) OPENMP=1
			;;
			h) usage; exit 1
			;;
		esac
	done	

	source ./scripts/config.sh
	
	echo "Running scaling.sh:"
	echo "APP: ${APP}"
	echo "PROBLEM: ${PROBLEM}"
	echo "PATTERN: ${PATTERN}"
	echo "ARCH: ${ARCH}"
	echo "PLOTTING: ${PLOT}"

	echo "MPI SCALING: ${MPI}"
	if [[ "${MPI}" -eq "1" ]]; then
		echo "RANK LIST: ${ranklist[*]}"
		echo "BINDING: ${BINDING}"
	fi

	echo "OPENMP SCALING: ${OPENMP}"
	if [[ "${OPENMP}" -eq "1" ]]; then
		echo "THREAD LIST: ${threadlist[*]}"
	fi

	cd ${HOMEDIR}
	source ${MODULEFILE}

	# Ensure that we got all the arguments
	if [[ -z "${APP}" || -z "${PROBLEM}" || -z "${PATTERN}" || -z "${ARCH}" ]] ; then
		usage
		exit 1
	fi

	JSON=${HOMEDIR}/patterns/${APP}/${PROBLEM}/${PATTERN}.json

	mkdir -p spatter.scaling/${ARCH}/${APP}/${PROBLEM}/${PATTERN}
			
	cd spatter.scaling/${ARCH}/${APP}/${PROBLEM}/${PATTERN}

	if [[ "${OPENMP}" -eq "1" ]]; then
		for thread in ${threadlist[@]}; do
			export OMP_NUM_THREADS=${thread}

			${SPATTER} -pFILE=${JSON} -q3 > openmp_1r_${thread}t.txt
		done
	fi

	if [[ "${MPI}" -eq "1" ]]; then
		export OMP_NUM_THREADS=1
		for rank in ${ranklist[@]}; do
			if [[ "${BINDING}" -eq "1" ]]; then
				srun -n ${rank} --cpu-bind=core ${SPATTER} -pFILE=${JSON} -q3 > mpi_${rank}r_1t.txt
			else
				srun -n ${rank} ${SPATTER} -pFILE=${JSON} -q3 > mpi_${rank}r_1t.txt
			fi

			mkdir -p ${rank}r

			num_patterns=`cat ${JSON} | grep -o -P 'kernel.{0,20}' | wc -l`
			num_patterns="$((num_patterns-1))"

			for pattern in $(seq 0 ${num_patterns}); do
				cat mpi_${rank}r_1t.txt | grep "^${pattern} " | awk '{print $3}' > ${rank}r/${rank}r_1t_${pattern}p.txt.tmp
				cat ${rank}r/${rank}r_1t_${pattern}p.txt.tmp | awk '{$1=$1};1' > ${rank}r/${rank}r_1t_${pattern}p.txt
				rm ${rank}r/${rank}r_1t_${pattern}p.txt.tmp
			done
		done
	
		if [[ "${PLOT}" -eq "1" ]]; then
			cd ${HOMEDIR}
			mkdir -p figures/${ARCH}/${APP}/${PROBLEM}/${PATTERN}
			python3 scripts/plot_mpi.py spatter.scaling/${ARCH}/${APP}/${PROBLEM}/${PATTERN} ${ARCH}
		fi
	fi
fi
