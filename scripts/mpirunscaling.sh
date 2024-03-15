#!/bin/bash

usage() {
	echo "Usage ./scaling.sh -a <application> -p <input problem> -f <pattern> -n <arch> [-b 'toggle boundary limit'] [-c 'toggle core binding'] [-g 'toggle gpu'] [-s 'toggle pattern size list'] [-t 'toggle throughput plots'] [-w 'toggle weak scaling'] [-x 'toggle plotting']
		-a : Specify the name of the application (see available apps in the patterns sub-directory)
		-p : Specify the name of the input problem (see available problems in the application sub-directory)
		-f : Specify the base name of the input JSON file containing the gather/scatter pattern (see available patterns in the input problem subdirectory)
		-n : Specify the test name you would like to use to identify this run (used to appropriately save data)
		-c : Optional, toggle core binding (default: off)
		-g : Optional, toggle gpu (default: off/cpu)
                -m : Optional, toggle atomics (default: off/no atomics)
		-r : Optional, toggle count parameter on pattern with countlist (default: off)
		-s : Optional, toggle pattern size limit on pattern with sizelist (default: off)
		-t : Optional, toggle throughput plot generation (optional, default: off)
		-w : Optional, enable weak scaling (default: off, strong scaling)
		-x : Optional, toggle plotting/post-processing. Requires python3 environment with pandas, matplotlib (default: on)"
}

if [ $# -lt 3 ] ; then
	usage
else
        SCALINGDIR="spatter.scaling"
        WEAKSCALING=0
	PLOT=1
        ATOMIC=0
	BINDING=0
	COUNT=0
	PSIZE=0
	GPU=0
	THROUGHPUT=0
	while getopts "a:f:p:n:cgmrstwx" opt; do
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
			g) GPU=1
			;;
                        m) ATOMIC=1
                        ;;
			r) COUNT=1
			;;
			s) PSIZE=1
			;;
			t) THROUGHPUT=1
			;;
			w) WEAKSCALING=1
			;;
			x) PLOT=0
			;;
			h) usage; exit 1
			;;
		esac
	done	

	if [[ "${GPU}" -eq "1" ]]; then
		source ./scripts/gpu_config.sh
	else
		source ./scripts/cpu_config.sh
	fi

	export OMP_NUM_THREADS=1
	
	echo "Running scaling.sh:"
	echo "APP: ${APP}"
	echo "PROBLEM: ${PROBLEM}"
	echo "PATTERN: ${PATTERN}"
	echo "RUNNAME: ${RUNNAME}"
	echo "GPU: ${GPU}"
        echo "ATOMIC: ${ATOMIC}"
	echo "PLOTTING: ${PLOT}"
	if [[ "${PLOT}" -ne "1" ]]; then
		echo "Plotting disabled, turning off throughput plots"
		THROUGHPUT=0
	fi
	echo "THROUGHPUT PLOTS: ${THROUGHPUT}"

        if [[ "${WEAKSCALING}" -eq "1" ]]; then
               	echo "Weak Scaling"	
		SCALINGDIR="spatter.weakscaling"
	else
               	echo "Strong Scaling"
		SCALINGDIR="spatter.strongscaling"
	fi

	if [[ "${GPU}" -eq "1" ]]; then
		echo "GPU Run, turning off core binding"
		BINDING=0
	fi

	echo "COUNT: ${COUNT}"
	if [[ "${COUNT}" -eq "1" ]]; then
		echo "COUNT LIST: ${countlist[*]}"
	fi

	echo "PATTERN SIZE: ${PSIZE}"
	if [[ "${PSIZE}" -eq "1" ]]; then
		echo "PATTERN SIZE LIST: ${sizelist[*]}"
	fi

	echo "RANK LIST: ${ranklist[*]}"
	echo "BINDING: ${BINDING}"
	echo ""

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

	for i in ${!ranklist[*]}; do

		cp ${JSON} ${JSON}.orig

		CFILE="_c1"
		SFILE="_s0"

		if [[ "${COUNT}" -eq "1" ]]; then
			CFILE="_${countlist[i]}c"
			sed -Ei 's/"count":1/"count": '${countlist[i]}'/g' ${JSON}
		fi

		if [[ "${PSIZE}" -eq "1" ]]; then
			SFILE="_${sizelist[i]}s"
			sed -Ei 's/\}/\, "pattern-size": '${sizelist[i]}'\}/g' ${JSON}
		fi

		if [[ "${GPU}" -eq "1" ]]; then
			sed -Ei 's/\}/\, "local-work-size": 1024\}/g' ${JSON}
		fi

		# Core Binding
		if [[ "${BINDING}" -eq "1" ]]; then	
			CMD="mpirun -n ${ranklist[i]} --bind-to=core ${SPATTER} -pFILE=${JSON} -q3"

			# Atomics
			if [[ "${ATOMIC}" -ne "0" ]]; then
 				sed -Ei 's/\}/\, "atomic-writes": 1\}/g' ${JSON}
			fi
	
			# Strong Scaling
			if [[ "${WEAKSCALING}" -ne "1" ]]; then
 				sed -Ei 's/\}/\, "strong-scale": 1\}/g' ${JSON}
			fi

		# No Core Binding
		else
			CMD="mpirun -n ${ranklist[i]} ${SPATTER} -pFILE=${JSON} -q3"

			# Atomics
			if [[ "${ATOMIC}" -ne "0" ]]; then
 				sed -Ei 's/\}/\, "atomic-writes": 1\}/g' ${JSON}
			fi
	
			# Strong Scaling
			if [[ "${WEAKSCALING}" -ne "1" ]]; then
				sed -Ei 's/\}/\, "strong-scale": 1\}/g' ${JSON}
			fi
		fi

		echo ${CMD}
		${CMD} > mpi_${ranklist[i]}r${CFILE}${SFILE}.txt

		mv ${JSON}.orig ${JSON}

		mkdir -p ${ranklist[i]}r

		num_patterns=`cat ${JSON} | grep -o -P 'kernel.{0,20}' | wc -l`
		num_patterns="$((num_patterns-1))"

		for pattern in $(seq 0 ${num_patterns}); do
			cat mpi_${ranklist[i]}r${CFILE}${SFILE}.txt | grep "^${pattern} " | awk '{print $2}' > ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.tmp.bytes
			cat ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.tmp.bytes | awk '{$1=$1};1' > ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.bytes
			rm ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.tmp.bytes

			cat mpi_${ranklist[i]}r${CFILE}${SFILE}.txt | grep "^${pattern} " | awk '{print $4}' > ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.tmp
			cat ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.tmp | awk '{$1=$1};1' > ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt
			rm ${ranklist[i]}r/${ranklist[i]}r${CFILE}${SFILE}_${pattern}p.txt.tmp
		done
	done

	echo ""
	
	if [[ "${PLOT}" -eq "1" ]]; then
		cd ${HOMEDIR}
		mkdir -p figures/${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN}
		echo "Plotting Results..."
		python3 scripts/plot_mpi.py ${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN} ${RUNNAME} ${WEAKSCALING} ${THROUGHPUT}
		echo ""
	fi

	echo "See ${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN} and figures/${SCALINGDIR}/${RUNNAME}/${APP}/${PROBLEM}/${PATTERN} for results"
fi
