# *RAD_demultiplex

Scripts to demultiplex internally barcoded fastq files on a SLURM scheduled HPC cluster in parallel.  With some mild hacking, this will run on a workstation in bash.  Each pair of fastq files to be demultiplexed can be run on a different thread if multiple files are specified in the `DMXfiles` and `FQfiles` variables, see *To Run* below. Demultiplexed fastq files are saved to directories in the `pwd`.

ddRAD_demultiplex.sbatch is for double-digest RAD data

newRAD_demultiplex.sbatch is for single-digest RAD data that has 1 ligated barcode followed by ezRAD sequencing (aka newRAD or bestRAD)
* Note that `process_radtags` which is harnessed by this script cannot handle
  * The remaining restriction site before the barcode, for SbfI, it's `GG`, so it should be added to the barcode in the demultiplex decode files
  * *_Indels at the beginning of the sequence reads, which are quite common. I have to code a solution to this using `agrep ` _*

## To Run

* Prepare your files.  There should be 1 demultiplex decode file per pair of fastq files (assuming paired end sequencing, R1 & R2), and each should be formatted with the first column being the barcodes, a tab, and the second column being the base name of the resulting demultiplexed sequences:
  
  ```
  GGAAGCCGGT      PIRE2019-Ssp-C-Gub_096-Plate1Pool6Seq1-2G-L4
  GGCGATGCTC      PIRE2019-Ssp-C-Gub_068-Plate1Pool6Seq1-2G-L4
  ```
  
  The base names of the demultiplex decode files should match those of the fq files they refer to, and the code assumes that the name of the   demultiplex decode files ends with `_demultiplex.txt`.  For example, consider the following fq.gz and demultiplex files that don't match the desired format:
  
  ```
  20180215_opihi_2017Cex_P1P1_S109_L5678_R1.fq.gz
  20180215_opihi_2017Cex_P1P1_S109_L5678_R2.fq.gz
  20180215_opihi_2017Cex_P1P2_S110_L5678_R1.fq.gz
  20180215_opihi_2017Cex_P1P2_S110_L5678_R2.fq.gz
  OpihiSK2017Plate1Pool1_demultiplex.txt
  OpihiSK2017Plate1Pool2_demultiplex.txt
  ```
  
  The demultiplex files can be renamed as follows to conform with the desired format:
  
  ```
  ls *.txt > filesToRename.txt
  ls *R1*gz | sed 's/_R1\.fq\.gz//g' > desired_basenames.txt
  parallel --no-notice -kj10 --link mv {1} {2}_demultiplex.txt :::: filesToRename.txt desired_basenames.txt
  ```
  
  ```
  20180215_opihi_2017Cex_P1P1_S109_L5678_demultiplex.txt
  20180215_opihi_2017Cex_P1P1_S109_L5678_R1.fq.gz
  20180215_opihi_2017Cex_P1P1_S109_L5678_R2.fq.gz
  20180215_opihi_2017Cex_P1P2_S110_L5678_demultiplex.txt
  20180215_opihi_2017Cex_P1P2_S110_L5678_R1.fq.gz
  20180215_opihi_2017Cex_P1P2_S110_L5678_R2.fq.gz
  ```

* Clone this repo to your computer
  ```
  git clone https://github.com/cbirdlab/RAD_demultiplex.git
  ```

* Copy the appropriate script to the directory where you want the demultiplexed files to be saved.

* No commandline arguments are accepted.  To specify where your data is, edit the following variables which hold the paths to the demultiplex decode and fastq files as well as the READ1 & READ2 file extensions used:
  ```
  #populate variables
  DMXfiles=*_demultiplex.txt
  FQfiles=*_1.fq.gz
  R1Ext=_1.fq.gz
  R2Ext=_2.fq.gz
  ```

* Edit the following `SBATCH` commands to work with your cluster
  ```
  #SBATCH -p normal
  #SBATCH --nodes=1

  #load software tools
  module load stacks
  module load parallel
  ```

* Run the script
  ```
  sbatch ddRAD_demultiplex.sbatch
  ```
  or
  ```
  sbatch newRAD_demultiplex.sbatch
  ```
