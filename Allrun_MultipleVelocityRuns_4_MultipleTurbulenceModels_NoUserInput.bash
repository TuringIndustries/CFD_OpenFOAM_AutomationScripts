#!/bin/bash

cd ${0%/*} || exit 1    # run from this directory

. ${WM_PROJECT_DIR:?}/bin/tools/RunFunctions # Source the OpenFoam runFunctions

script_base_folder=$PWD

# Case assumed to have failed if this string is not present in the log.simpleFoam file
error_check_string="Finalising parallel run"
error_check_file="log.simpleFoam"

#------------ This script is intented for sequential runs of k_epsilon and kOmegaSSt (or any turbulence models) runs ----------

#---------------------------------------------------------------------------------------------------
#  First, kEpsilon runs; low resolution mesh case is solved using potentialFoam + solver -----------
#  Then the first case solution is mapped to the any finer resolution mesh of the same turbulence model--
#  Then, the high resolution latest turbulence model case is mapped to the low resolution kOmega solution----------

#---------------------------And the process repeated...---------------------------------------------

#  Aiming to obtain a high resolution kEpsilon, and kOmegaSST (or any turbulence model) solution for the same domain parameters
#-------------------(e.g for a particular flow speed for the same domain)--------------------------
#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------
#-------------------This script assumes that the case setup is as follows:--------------------------

# The case has a parent folder containing three folders; 0_orig_ALL, Original_Setup_ALL, and System_changes_All


#  ----------------------- For Original_Setup_ALL -----------------------------------------------
# Cases for each turbulence model should be stored in the Original_Setup_ALL folder in seperate folders for each Turbmodel
# Each case run folder should contain only the constant and system folders, and the 0 folder will be copied from 0_orig_ALL for each case.

# Names for each turbulence model folder Original_Setup_ALL should begin with "1_kEpsilon_", "2_kOmega_", "3_*" etc, to define the order of simulation
# Internal cases should be ordered so the low resolution mesh begins with "1_*", and the higher mesh's to be tested are "2_ExampleCase", "3_ExampleCase" etc, again to define the order


#  ------------------------ For 0_orig_ALL ---------------------------------------------------
# The runs are determined by the number of 0.orig folders in the 0_orig_ALL case folder, which should be labelled "0.1Run1_example", "0.Velocity_3_05_m_s" etc.:
## The 0.orig file extension is used as the basename:
# - e.g. if each file is 0.Run1_Velcocity_3_05_m_s will give a run name of Run1_Velcocity_3_05_m_s

# For each 0.orig folder a new case folder will be created, and the runs for each turbulence model (in this case k-Epsilon and k_OmegaSST) will be completed 
# based on the number of folders in Original_Setup_ALL, with each folder corrsponding to a particular mesh or similar parameter case to be run'


#  ------------------------ For System_changes_ALL ---------------------------------------------------

#--The forces, and forceCoeffs function objects need to be modified for certain changes (flow velocity, density, geometry)
#--Include these entires for each velocity run in a folder called the same name as the 0.orig folder for each run, to be copied into the system folder of each case using the -force option


#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------

#--Apart from that the script should (hopefully) then run for different case setups -----------------
#--Need to be careful if the process fails at certain points, then the solution won't run for the subsequent cases until it reaches a new velocity run...
# Can be modified to alter anything in the 0 folder, system folder, (and easily constant folder for each case). 

# Can be called by a parent script to first run meshing for all of the specified runs, before copying them to the correct folders, but may be better to run seperately

# The names of the setup folders can be set to a user input variable if required by setting Original_Setup_ALL="Location/Name of base case..." etc

# For each 0-folder relating to a new velocity run – stored somewhere in the case folder 

echo; printf "All of the Allrun scripts should be in the cwd. Please input the full path to the folder which contains the 0_orig_ALL, System_changes_ALL and Original_Setup_ALL folders. "; echo; echo;

SOME_LOCATION=$script_base_folder

echo; printf "Running from $SOME_LOCATION"; echo;

echo; printf "Waiting 5s before starting run, use ctrl+Z to cancel... "
echo;
sleep 5

# echo; printf "Please input the exact name of the turbulence model used in the first run as it appears in constant/momentumTransport in the Original_Setup_ALL folder"

# read Base_Turbulence_Model



#--------------------------------Solver runs for each new parameter run (In this case altered velocity runs)---------------------------------------
# The runs are determined by the number of 0.orig folders in the 0_orig_ALL case folder:
# For each 0.orig folder a new case folder will be created, and the runs for each turbulence model (in this case k-Epsilon and k_OmegaSST) will be completed 
# based on the number of folders in Original_Setup_ALL, with each folder corrsponding to the mesh's or similar parameter cases that are to be run


# For each 0.orig folder in 0_orig_ALL in the directory given as user input
for zero_orig_folder in $SOME_LOCATION/0_orig_ALL/*; do 
	
	echo; printf "Currently running using $zero_orig_folder case"
	zero_basename=$(basename "$zero_orig_folder")
	echo;
	echo; printf "Zero run basename is: $zero_basename"; echo;
	
	# ------------------Setting up variables to reset for each velocity run------------------------------
	# Create a counter for internal runs of each turulence model and each internal run for each tubrulence model
	turbulence_run_number=$(( 1 ))
	internal_run_number=$(( 1 ))
	
	echo "turbulence run counter = $turbulence_run_number"
	echo "internal counter = $internal_run_number"
	
	# Use the 0.orig file extension as the basename:
	# - e.g. if each file is 0.Run1_Velcocity_3_05_m_s will give a run name of Run1_Velcocity_3_05_m_s
	run_name="${zero_orig_folder##*.}"
	echo; printf "The current name for the case folder relating to current 0.orig run is: $run_name"; echo;

	# All cases should already set to the desired model for each turbulence run folder in Original_Setup_ALL. 
	echo; printf "Creating run folder for current $SOME_LOCATION/$run_name.. "; echo;
	
	# create a new case run folder for each 0.orig file"
	mkdir -p $SOME_LOCATION/$run_name

	#------------------------------------------------------------------------------------------------------------------------------------------------
	# Copy All cases to run for each 0.orig run. This should contain folders for each turbulence model ordered as 1_KEpsilon*, 2_KOmegaSST*, 3*... etc.
	# Each of these folder should contain the case setup for all mesh runs, ordered in refinement as: 1_Mesh_*, 2*, 3*... etc.
	# Each case run folder should contain only the constant and system folders, and the 0 folder will be copied from 0_orig_ALL for each case.
	
	# All cases should already set to the desired model for each turbulence run folder in Original_Setup_ALL. 
	echo; printf "Copying Base_Directory/Original_Setup_ALL/* to $Base_Directory/$run_name/ "; echo	
	cp -rn $SOME_LOCATION/Original_Setup_ALL/* $SOME_LOCATION/$run_name/

	#------------------------ Solver runs for each turbulence model----------------------------------------
	
	# For each parent folder (The turbulence model cases) in the Original_Setup_ALL folder"
	for parent_folder in $SOME_LOCATION/$run_name/*; do
	
		echo; printf "Running cases for $parent_folder/$run_name "; echo

		parent_basename=$(basename "$parent_folder")
		echo; printf "Turbulence model run basename is: $parent_basename"; echo
	
		# For each case name which has been copied from the base setup folder (Original_Setup_ALL) to be used for the current case run 
		for case in $SOME_LOCATION/$run_name/$parent_basename/*; do
			
			case_basename=$(basename "$case")

			echo; printf "case basename is: $case_basename"; echo

			
			
			# For each turbulence model case folder run
			echo; printf "Copying 0 folder and any system folder entries for $case_basename ... "; echo


	
			echo; printf "Running from $case(should be full path)"; echo

			
			# copy zero folder to the current veloctiy run for each case setup to be run
			cp -rn $SOME_LOCATION/0_orig_ALL/$zero_basename $SOME_LOCATION/$run_name/$parent_basename/$case_basename/0.orig
			

			sleep 5
			# Any neccessary function objects to the current veloctiy run system folder for each case setup to be run (e.g. different forceCoeffs for each run		
			cp -rf $SOME_LOCATION/System_changes_ALL/$zero_basename/* $SOME_LOCATION/$run_name/$parent_basename/$case_basename/system/

				
			echo; printf "Successfully copied the $zero_basename folder to $run_name/$parent_basename/$case_basename/0.orig (should be full paths here)... "
			echo;
	
		
			# If the run is for the initialization run - then the case will be initialized with potential foam and solved
			if [ $turbulence_run_number -eq 1 ] && [ $internal_run_number -eq 1 ]; then
			
				echo; printf "The $case_basename is running as an initialization run (Option 1), to be solved with potentialFoam (basename path here)... "; echo
				
				# Change into the current case
				echo; printf "Changing directory to the current case to run solver... "; echo
				sleep 3
						
				cd  $SOME_LOCATION/$run_name/$parent_basename/$case_basename
				
				# Copy zero directory into place from 0.orig
				[ ! -d 0 ] && cp -r 0.orig 0
				
				# Decompose case for parallel run
				runApplication decomposePar > decomposePar2.log
				
				runParallel potentialFoam
				
				echo; printf "Calling potential foam Allrun script "; echo
				# Call potential foam Allrun script from the same folder as the original script
				$script_base_folder/Allrun_Solver_Parallel
			
				# Assign basename of cwd to a variable for new turbulence initialization runs
				previous_case=$PWD
				
				# Change back to the script folder
				echo; printf "The run for $run_name/$parent_basename/$case_basename is completed, changing back to script directory... "; ech
				
				cd $script_base_folder
				
				# Increase internal counter
				internal_run_number=$(( $internal_run_number + 1 ))
				echo "internal counter = $internal_run_number"											
					

			# If the run is for a new turbulence case then the 0 folder should be mapped from the finest case of the previous mesh and then ran
			else
				if [ $turbulence_run_number -ne 1 ] && [ $internal_run_number -eq 1 ]; then
					
					echo; printf "$case_basename is running as an initialization run (Option 2)"
					echo "This is for a new turbulence model, to be initialized by mapping the solution from $previous_case ... (full paths)"; 															echo		
				
				else 
					
					echo; printf "$case_basename is running by mapping from the previous case in the same turbulence model (Option 3)... (Full paths) "; echo;
				fi
					
				# Change into the current case
				cd  $SOME_LOCATION/$run_name/$parent_basename/$case_basename
				
				echo; printf "Running case from $PWD"; echo;
				
				# Map fields from most refined previous turbulence model
				echo; printf "The current case: $case_basename will be initialized by mapping the the solution from $previous_case ..."; echo;

				sleep 3		
				mapFields $previous_case -case $SOME_LOCATION/$run_name/$parent_basename/$case_basename -sourceTime latestTime -consistent > mapFields.log
				
				#--------------------------------------------------------------------------------------------------------------------------------------------
				# THIS SECTION MUST BE ALTERED BASED ON THE CHOICE OF TURBULENCE MODELS - IN THIS CASE THE SECOND MODEL IS K-OMEGA SST AND SO THE OMEGA FIELD MUST
				# BE COPIED AFTER BEING MAPPED FROM THE K-EPSILON CASE
				
				# Need to adjust for different turbulence models or create variable- But copies omega into place if being mapped from a different turbulence model
				if [ $turbulence_run_number -ne 1 ] && [ $internal_run_number -eq 1 ]; then
					echo; printf "Copying the omega field from $zero_orig_current since the run is being mapped from a different turbulence model   ... " 	
					echo;					
					cp -r $SOME_LOCATION/0_orig_ALL/$zero_basename/omega $SOME_LOCATION/$run_name/$parent_basename/$case_basename/0/omega
				fi				
				#-------------------------------------------------------------------------------------------------------------------------------------
				
				
				echo; echo "Decomposing current case..."; echo;

				# Decompose case for parallel run
				runApplication decomposePar > decomposePar2.log
				
				echo; printf "Calling Allrun script to run the mapped case... "
				echo;
				# Call fromMapFields Allrun script from the same folder as the original script
				$script_base_folder/Allrun_Solver_Parallel
				
				
																					
				# Assign basename of cwd to a variable for new turbulence initialization runs
				previous_case=$PWD
				
				
				# Change back to the script folder
				echo; printf "Run for $case_basename in $parent_basename has finished, changing back to script directory... "
				echo;
				cd $script_base_folder
				
				
				# Increase internal counter
				internal_run_number=$(( $internal_run_number + 1 ))	
				echo "internal counter = $internal_run_number"
					
			fi					
		done

		echo; printf "All runs completed for $parent_folder "
		echo;
		internal_run_number=$(( 1 ))
		echo "internal counter = $internal_run_number"; echo;
			
			
		# increase counter for tubrulence model and reset internal counter for cases inside each turbulence model case
		turbulence_run_number=$(( $turbulence_run_number + 1 ))	
		echo "turbulence run counter = $turbulence_run_number"; echo
	
	done
		
	echo; printf "All runs have completed for the current velocity run"
	echo;	

done

echo "All runs have completed for all velocity runs :)\n"

# End of script
