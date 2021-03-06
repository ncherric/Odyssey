#!/bin/bash

## Overview:
## ==================

## This script will:
	# 1) Create the Bash scripts used to execute Phasing jobs (autosomal and the X chromosome) on a system
	# 2) Submit the Bash scripts to the HPC queue at the user's request
	

# Source from .config files (Program options via Settings.conf & Program execs via Programs.conf)
# ----------------------------
	
	source Settings.conf
	
	# Load Odysseys Dependencies -- pick from several methods
	if [ "${OdysseySetup,,}" == "one" ]; then
		echo
		printf "\n\n Loading Odyssey's Singularity Container Image \n\n"
		source ./Configuration/Setup/Programs-Singularity.conf
	
	elif [ "${OdysseySetup,,}" == "two" ]; then
		echo
		printf "\n\n Loading Odyssey's Manually Configured Dependencies \n\n"
		source ./Configuration/Setup/Programs-Manual.conf
	else

		echo
		echo User Input Not Recognized -- Please specify One or Two
		echo Exiting Dependency Loading
		echo
		exit
	fi

	source .TitleSplash.txt


# Splash Screen
# --------------
printf "$Logo"


# Set Working Directory
# -------------------------------------------------
	echo
	echo Changing to Working Directory
	echo ----------------------------------------------
	echo ${WorkingDir}
		cd ${WorkingDir}
	
	echo
	echo Creating Imputation Project Folder within Phase Directory
	echo
		mkdir -p ./2_Phase/${BaseName}
		lfs setstripe -c 2 ./2_Phase/${BaseName}
		mkdir -p ./2_Phase/${BaseName}/Scripts2Shapeit
	
	echo
	echo Creating Phasing Scripts
	echo
	

## -------------------------------------------
## Phasing Script Creation for HPC (Chr1-22)
## -------------------------------------------

#Set Chromosome Start and End Parameters
	for chr in `eval echo {$PhaseChrStart..$PhaseChrEnd}`; do


#Search the reference directory for the chromosome specific reference map, legend, and hap files and create their respective variables on the fly

printf "\nProcessing Chromosome ${chr} Script \n"
echo -----------------------------------
echo

	echo "Looking in ./Reference For Reference Files "
	echo "Found the following references for Chromosome ${chr}: "

	GeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*chr${chr}[^[:digit:]]{1}.*|.*chr${chr}[^[:digit:]]{1}.*map.*")"
		printf "   Genetic Map File: $GeneticMap \n"
	HapFile="$(ls ./Reference/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*hap\.gz")"
		printf "   Haplotpe File: $HapFile \n"
	LegendFile="$(ls ./Reference/ | egrep --ignore-case ".*chr${chr}[^[:digit:]]{1}.*legend\.gz")"
		printf "   Legend File: $LegendFile \n \n"	


echo "#!/bin/bash


cd ${WorkingDir}

# Phase Command to Phase Chromosomes
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out -N PChr${chr}_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
			

time ${Shapeit2_Exec} \
--thread ${PhaseThreads} \
--input-bed ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr${chr} \
--input-map ./Reference/${GeneticMap} \
--output-max ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased \
--output-log ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr${chr}_Phased.log" > ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh


# Toggle that will turn script submission on/off
# -----------------------------------------------

if [ "${ExecutePhasingScripts}" == "T" ]; then


	if [ "${HPS_Submit}" == "T" ]; then

		echo
		echo Submitting Phasing script to HPC Queue
		echo
			qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out -N PChr${chr}_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh
			sleep 0.2
	else
		echo
		echo Submitting Phasing script to Desktop Queue
		echo
			sh ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.sh > ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr${chr}_P.out

			
	fi

fi

done



## ---------------------------------------
## Extra Step to Phase the X Chromosome
## ---------------------------------------

if [ "${PhaseX}" == "T" ]; then

## -------------------------------------------
## Phasing Script Creation for HPC (Chr23/X)
## -------------------------------------------

printf "\nProcessing X Chromosome Script \n"
echo -----------------------------------
echo

# Search the reference directory for the X chromosome specific reference map, legend, and hap files and create their respective variables on the fly
	
	echo "Looking in ./Reference For Reference Files "
	echo "Found the following references for Chromosome X: "

	XGeneticMap="$(ls ./Reference/ | egrep --ignore-case ".*map.*${XChromIdentifier}.*|.*${XChromIdentifier}.*map.*")"
		printf "   Genetic Map: $XGeneticMap \n"
	XHapFile="$(ls ./Reference/ | egrep --ignore-case ".*${XChromIdentifier}.*hap\.gz")"
		printf "   Haplotpe File: $XHapFile \n"
	XLegendFile="$(ls ./Reference/ | egrep --ignore-case ".*${XChromIdentifier}.*legend\.gz")"
		printf "   Legend File: $XLegendFile \n \n"

echo "#!/bin/bash

cd ${WorkingDir}

# Phase Command to Phase X Chromosome
	# Manual Command to Run:
	# qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out -N PChr23_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh

	

time ${Shapeit2_Exec} \
--thread ${PhaseThreads} \
--chrX \
--input-bed ./1_Target/${BaseName}/Ody2_${BaseName}_PhaseReady.chr23 \
--input-map ./Reference/${XGeneticMap} \
--output-max ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased \
--output-log ./2_Phase/${BaseName}/Ody3_${BaseName}_Chr23_Phased.log" > ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh


# Toggle that will turn script submission on/off
# -----------------------------------------------

	if [ "${ExecutePhasingScripts}" == "T" ]; then

	
		if [ "${HPS_Submit}" == "T" ]; then

			echo
			echo Submitting Phasing script to HPC Queue
			echo
				qsub -l nodes=1:ppn=${PhaseThreads},vmem=${Phase_Memory}gb,walltime=${Phase_Walltime} -M ${Email} -m ae -j oe -o ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out -N PChr23_${BaseName} ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh
				sleep 0.2
		else
			echo
			echo Submitting Phasing script to Desktop Queue
			echo
				sh ./2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.sh > ${WorkingDir}2_Phase/${BaseName}/Scripts2Shapeit/${BaseName}_Chr23_P.out

			
		fi		
	
	fi
fi	

echo
echo Done!
echo

