# Description

Please have a look at the Jupyter Notebook provided in this directory for
the workflow to set up `MESH` model using the `MESHFlow` Python package.

Forcing RDRS Processing Script
This script processes climate forcing data for the Nelson-Churchill River Basin using the RDRS dataset. It performs vector processing, file merging, and unit conversions. The script is designed to run on a high-performance computing cluster using SLURM.

SLURM Job Submission
Account: rpp-kshook
Nodes: 1
Tasks per Node: 1
Memory per CPU: 30G
Time Limit: 10 hours
Job Name: extRDRS
Email Notifications:
User: fuad.yassin@usask.ca
Types: BEGIN, END, FAIL
Usage
You can run the script with different sections enabled based on your needs:

To run all sections:
sbatch Forcing_RDRS_processingMet3.sh --section1 --section2 --section3
To run only Section 1:
sbatch Forcing_RDRS_processingMet3.sh --section1
To run only Section 2:
sbatch Forcing_RDRS_processingMet3.sh --section2
To run only Section 3:
sbatch Forcing_RDRS_processingMet3.sh --section3

Script Sections
Section 1: Python Script Execution
Runs a Python script to process vector-based forcing data.

Section 2: Merging Files
Merges yearly NetCDF files into a single file.

Section 3: Unit Conversions
Converts units for various variables in the merged NetCDF file.

Script Details
Environment Setup
Loads necessary modules for cdo and nco.

Input Variables
basin: Basin name (e.g., "ncrb")
start_year: Start year for forcing data (e.g., 1980)
end_year: End year for forcing data (e.g., 2018)
Paths to necessary files and directories.
Output
Merged NetCDF file with converted units.
Example Commands
# Running Section 1 only
sbatch Forcing_RDRS_processingMet3.sh --section1
# Running Section 2 only
sbatch Forcing_RDRS_processingMet3.sh --section2
# Running Section 3 only
sbatch Forcing_RDRS_processingMet3.sh --section3
# Running all sections
sbatch Forcing_RDRS_processingMet3.sh --section1 --section2 --section3