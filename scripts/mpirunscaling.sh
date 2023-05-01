#!/bin/bash

usage() {
	echo "Usage ./scaling.sh -a <application> -p <input problem> -f <pattern> -n <arch> [-c 'toggle core binding'] [-g <0/1 enable/disable plotting>] [-r 'toggle scaling with MPI'] [-w 'toggle weak scaling']
		-a : Specify the name of the application (see available apps in the patterns sub-directory)
		-p : Specify the name of the input problem (see available problems in the application sub-directory)
		-f : Specify the base name of the input JSON file containing the gather/scatter pattern (see available patterns in the input problem subdirectory)
		-n : Specify the test name you would like to use to identify this run (used to appropriately save data)
		-c : Optional, toggle core binding (default: off)
		-g : Optional, toggle plotting/post-processing. Requires python3 environment with pandas, matplotlib (default: on)
		-r : Optional, enable scaling with MPI (default: off)
		-w : Optional, enable weak scaling (default: off, strong scaling)"	
}

if [ $# -lt 3 ] ; then
	usage
else
        SCALINGDIR="spatter.scaling"
        WEAKSCALING=0
	MPI=0
	PLOT=1
	BINDING=0
	while getopts "a:f:p:n:cgrw" opt; do
		case $opt in 
			a) APP=$OPTARG
			;;
			f) PATTERN=$OPTARG
			;;
			p) PROBLEM=$OPTARG
			;;
			n) RUNNAME=$OPTARG
			;;
			c) BINDING=1
			;;
			g) PLOT=$OPTARG
			;;
			r) MPI=1
			;;
			w) WEAKSCALING=1
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
	echo "RUNNAME: ${RUNNAME}"
	echo "PLOTTING: ${PLOT}"

	echo "MPI SCALING: ${MPI}"
	if [[ "${MPI}" -eq "1" ]]; then
                if [[ "${WEAKSCALING}" -eq "1" ]]; then
                	echo "Weak Scaling"
                        SCALINGDIR="spatter.weakscaling"
                else
                	echo "Strong Scaling"
			echo "PATTERN SIZE LIST: ${sizelist[*]}"
			SCALINGDIR="spatter.strongscaling"
                fi
		echo "RANK LIST: ${ranklist[*]}"
		echo "BINDING: ${BINDING}"
	fi

	cd ${HOMEDIR}
	source ${MODULEFILE}

	# Ensure that we got all the arguments
	if [[ -z "${APP}" || -z "${PROBLEM}" || -z "${PATTERN}" || -z "${RUNNAME}" ]] ; then
		usage
		exit 1
	fi

	JSON=${HOMEDIR}/patterns/${APP}/${PROBLEM}/${PATTERN}.json

	mkdir -p ${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN}
			
	cd ${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN}

	if [[ "${MPI}" -eq "1" ]]; then
		export OMP_NUM_THREADS=1
		for i in ${!ranklist[*]}; do
			if [[ "${BINDING}" -eq "1" ]]; then	
				CMD="mpirun -n ${ranklist[i]} --bind-to core ${SPATTER} -pFILE=${JSON} -e ${boundarylist[i]} -q3"
				if [[ "${WEAKSCALING}" -ne "1" ]]; then
					cp ${JSON} ${JSON}.orig
					sed -Ei 's/\}/\, "pattern-size": '${sizelist[i]}'\}/g' ${JSON}
				fi
			else
				CMD="mpirun -n ${ranklist[i]} ${SPATTER} -pFILE=${JSON} -e ${boundarylist[i]} -q3"
				if [[ "${WEAKSCALING}" -ne "1" ]]; then
					cp ${JSON} ${JSON}.orig
					sed -Ei 's/\}/\"pattern-size": '${sizelist[i]}'\}/g' ${JSON}
				fi
			fi

			echo ${CMD}
			${CMD} > mpi_${ranklist[i]}r_1t.txt

                        if [[ "${WEAKSCALING}" -ne "1" ]]; then
				mv ${JSON}.orig ${JSON}
                        fi

			mkdir -p ${ranklist[i]}r

			num_patterns=`cat ${JSON} | grep -o -P 'kernel.{0,20}' | wc -l`
			num_patterns="$((num_patterns-1))"

			for pattern in $(seq 0 ${num_patterns}); do
				cat mpi_${ranklist[i]}r_1t.txt | grep "^${pattern} " | awk '{print $3}' > ${ranklist[i]}r/${ranklist[i]}r_1t_${pattern}p.txt.tmp
				cat ${ranklist[i]}r/${ranklist[i]}r_1t_${pattern}p.txt.tmp | awk '{$1=$1};1' > ${ranklist[i]}r/${ranklist[i]}r_1t_${pattern}p.txt
				rm ${ranklist[i]}r/${ranklist[i]}r_1t_${pattern}p.txt.tmp
			done
		done

		echo ""
	
		if [[ "${PLOT}" -eq "1" ]]; then
			cd ${HOMEDIR}
			mkdir -p figures/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN}
			echo "Plotting Results..."
			python3 scripts/plot_mpi.py ${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN} ${RUNNAME}
			echo ""
		fi
	fi

	echo "See ${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN} for results"
fi
