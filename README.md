**QE4dimer** is a collection of Perl scripts designed to automate and streamline the setup, submission, and monitoring of Quantum ESPRESSO (QE) calculations, particularly for dimer systems. The toolkit facilitates the generation of input files, job submission scripts, and the management of computational workflows, making it easier for researchers to perform high-throughput calculations using QE.

## Features

* **Automated Input Generation**: Scripts like `make_data4dimer.pl` and `data2QE.pl` assist in creating QE-compatible input files from raw data.

* **Job Submission Management**: Tools such as `submit4allDead.pl` and `submit_allslurm_sh.pl` help in generating and submitting job scripts to SLURM-managed clusters.

* **Workflow Monitoring**: `check_QEjobs.pl` allows users to monitor the status of their QE jobs, ensuring efficient tracking and management.

* **Modular Configuration**: Modules like `ModQEin4Dead.pl`, `ModQEsetting.pl`, and `Modsh4Dead.pl` provide customizable settings for QE input files and shell scripts.

* **Element Data Handling**: The `elements.pm` module and `periodic_table.json` file offer elemental data support for input generation.

* **Get suggested rcut and rcut_smth**: try post_processing.pl

## Prerequisites

* **Perl**: Ensure that Perl is installed on your system.

* **Quantum ESPRESSO**: Install QE and ensure its executables are accessible in your system's PATH.

* **SLURM**: For job submission, a SLURM workload manager should be available.

## Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/jushinpon/QE4dimer.git
   cd QE4dimer
   ```



2. **Set Permissions**:

   Ensure that the Perl scripts are executable:

   ```bash
   chmod +x *.pl
   ```



## Usage

1. **Generate Data Files**:

   Use `make_data4dimer.pl` to create data files for your dimer systems.

   ```bash
   ./make_data4dimer.pl
   ```



2. **Convert Data to QE Input**:

   Transform the generated data files into QE input files using `data2QE.pl`:

   ```bash
   ./data2QE.pl
   ```



3. **Submit Jobs**:

   Prepare and submit your jobs to the SLURM scheduler:

   ```bash
   ./submit4allDead.pl
   ./submit_allslurm_sh.pl
   ```



4. **Monitor Jobs**:

   Check the status of your QE jobs:

   ```bash
   ./check_QEjobs.pl
   ```



## File Overview

* **make_data4dimer.pl**: Generates data files for dimer systems.

* **data2QE.pl**: Converts data files into QE-compatible input files.

* **submit4allDead.pl**: Creates job submission scripts for all prepared inputs.

* **submit_allslurm_sh.pl**: Submits all job scripts to the SLURM scheduler.

* **check_QEjobs.pl**: Monitors the status of submitted QE jobs.

* **ModQEin4Dead.pl**, **ModQEsetting.pl**, **Modsh4Dead.pl**: Modules for configuring QE input files and shell scripts.

* **elements.pm**: Perl module containing elemental data for input generation.

* **periodic_table.json**: JSON file with periodic table data used by `elements.pm`. This file is copied from the official dpdata reposotory.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your enhancements.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

Developed by [jushinpon](https://github.com/jushinpon).

