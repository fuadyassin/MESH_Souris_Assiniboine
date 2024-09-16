#!/bin/bash
#SBATCH --account=rpp-kshook
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --mem-per-cpu=30G
#SBATCH --time=24:00:00
#SBATCH --job-name=vectForcRDRS
#SBATCH --mail-user=fuad.yassin@usask.ca
#SBATCH --mail-type=BEGIN,END,FAIL

: '
# Forcing RDRS Processing Script

This script processes climate forcing data for the vector-based MESH RDRS dataset. It supports both parallel processing of individual years using SLURM array jobs and full processing across all years in a single job.

## Usage

- To process each year in parallel using array jobs:
  sbatch --array=0-38 Forcing_RDRS_processingMet3.sh --section1
  (where 0 corresponds to the start year 1980 and 38 corresponds to 2018)

- To process all data in a single job:
  sbatch Forcing_RDRS_processingMet3.sh --section1 --section2 --section3

## Script Sections

### Section 1: Python Script Execution for a Single Year

### Section 2: Merging Files Across All Years

### Section 3: Unit Conversions

## Example Commands

# Running all sections in a single job
sbatch Forcing_RDRS_processingMet3.sh --section1 --section2 --section3
sbatch Forcing_RDRS_processingMet3.sh --section3

# Running each year in parallel using array jobs
sbatch --array=0-38 Forcing_RDRS_processingMet3.sh --section1
'

# Parameters
basin="sras"
start_year=1980
end_year=2018
input_forcing_easymore='/scratch/fuaday/sras-agg-model/easymore-outputs'
ddb_remapped_output_forcing='/scratch/fuaday/sras-agg-model/easymore-outputs2'
input_basin='/scratch/fuaday/sras-agg-model/geofabric-outputs/sras_subbasins_MAF_Agg.shp'
input_ddb='/scratch/fuaday/sras-agg-model/MESH-sras-agg/MESH_drainage_database.nc'
dir_merged_file="/scratch/fuaday/sras-agg-model/easymore-outputs-merged"
merged_file="${dir_merged_file}/${basin}_rdrs_${start_year}_${end_year}_v21_allVar.nc"

# Activate the virtual environment
source $HOME/virtual-envs/scienv/bin/activate
module load StdEnv/2020
module load gcc/9.3.0
module restore scimods
module load cdo
module load nco

# Function to run Section 1 for a single year
function run_section1_single_year {
  local year=$1
  local start_time=$(date +%s)
  echo "Running Section 1 for year $year: Python script for vector processing"

  # Execute the Python script for a single year
  python RDRS_MESH_vectorbased_forcingMet2.py single_year \
    --input_directory "$input_forcing_easymore" \
    --output_directory "$ddb_remapped_output_forcing" \
    --input_basin "$input_basin" \
    --input_ddb "$input_ddb" \
    --year $year

  local python_exit_code=$?
  if [ $python_exit_code -ne 0 ]; then
    echo "Python script for year $year failed with exit code $python_exit_code."
    exit $python_exit_code
  fi
  
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  echo "Section 1 for year $year completed: Python script executed in $elapsed_time seconds."
}

# Function to run Section 1 for all years (not using array jobs)
function run_section1_all_years {
  local start_time=$(date +%s)
  echo "Running Section 1: Python script for vector processing"

  # Execute the Python script for the range of years
  python RDRS_MESH_vectorbased_forcingMet2.py all_years \
    --input_directory "$input_forcing_easymore" \
    --output_directory "$ddb_remapped_output_forcing" \
    --input_basin "$input_basin" \
    --input_ddb "$input_ddb" \
    --start_year $start_year \
    --end_year $end_year

  local python_exit_code=$?
  if [ $python_exit_code -ne 0 ]; then
    echo "Python script for all years failed with exit code $python_exit_code."
    exit $python_exit_code
  fi
  
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  echo "Section 1 completed: Python script executed in $elapsed_time seconds."
}

# Function to run Section 2: Merging files
function run_section2 {
  local start_time=$(date +%s)
  echo "Running Section 2: Merging files"
  if [ ! -d "$dir_merged_file" ]; then
      mkdir -p "$dir_merged_file"
      echo "Directory created: $dir_merged_file"
  else
      echo "Directory already exists: $dir_merged_file"
  fi

  merge_cmd="cdo mergetime"
  for (( year=$start_year; year<=$end_year; year++ ))
  do
      merge_cmd+=" ${ddb_remapped_output_forcing}/remapped_remapped_${basin}_model_${year}*.nc"
  done
  $merge_cmd "$merged_file"

  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  echo "Section 2 completed: Files merged in $elapsed_time seconds."
}

# Function to run Section 3: Unit conversions
function run_section3 {
  local start_time=$(date +%s)
  echo "Running Section 3: Converting units"
  ncatted -O -a units,RDRS_v2.1_P_TT_09944,o,c,"K" "$merged_file"
  ncatted -O -a units,RDRS_v2.1_P_P0_SFC,o,c,"Pa" "$merged_file"
  ncatted -O -a units,RDRS_v2.1_P_UVC_09944,o,c,"m s-1" "$merged_file"
  ncatted -O -a units,RDRS_v2.1_A_PR0_SFC,o,c,"mm s-1" "$merged_file"

  temp_file="${dir_merged_file}/${basin}_temp.nc"

  cdo -z zip -b F32 -aexpr,'RDRS_v2.1_P_TT_09944=RDRS_v2.1_P_TT_09944 + 273.15; RDRS_v2.1_P_P0_SFC=RDRS_v2.1_P_P0_SFC * 100.0; RDRS_v2.1_P_UVC_09944=RDRS_v2.1_P_UVC_09944 * 0.514444; RDRS_v2.1_A_PR0_SFC=RDRS_v2.1_A_PR0_SFC / 3.6' "$merged_file" "$temp_file"

  mv "$temp_file" "$merged_file"

  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  echo "Section 3 completed: Units converted in $elapsed_time seconds."
}

# Main execution logic based on command-line arguments
for arg in "$@"
do
    case $arg in
        --section1)
            if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
                run_section1_all_years
            else
                year=$((start_year + SLURM_ARRAY_TASK_ID))
                run_section1_single_year $year
            fi
            ;;
        --section2)
            run_section2
            ;;
        --section3)
            run_section3
            ;;
    esac
done
