#!/bin/bash

#SBATCH --job-name=
#SBATCH --time=96:00:00
#SBATCH -p normal
#SBATCH --nodes=1
#SBATCH --mail-user=
#SBATCH --mail-type=begin  # email me when the job starts
#SBATCH --mail-type=end    # email me when the job finish

module load stacks
module load parallel

#create the directory where the demultiplexed sequences will go
mkdir demultiplexed_seqs_$4

# make a list of generic file names
ls *_demultiplex.txt | sed 's/_demultiplex.txt//g' > y.txt 
ls *_R1*.fastq.gz | sed 's/_R1_001.fastq.gz//g' > x.txt  # makes a list variable with the correct file start format Read 1.fastq.gz files.
parallel --link "process_radtags -1 {1}_R1_001.fastq.gz -2 {1}_R2_001.fastq.gz -i gzfastq -b {2}_demultiplex.txt -r -e ecoRI -o demultiplexed_seqs_$4 -D" :::: x.txt :::: y.txt


# -1 designates the read 1 file in a set of paired-end sequences. This needs to match the sequence file name.
# -2 designates the read 2 file in a set of paired-end sequences. This needs to match the sequence file name.
# -i sets the input file type. This should not be changed
# -b designates the barcode file that is used to separate the barcodes and name individual sequence files. This should be changed to match your barcode file name.
# -r tells the program to rescue barcodes that have no more than 2 mismatches. You do not need to adjust this parameter
# -e indicates the radtag that the program should search for. This is the enzyme associated with the read 1 sequences
# -o is the output path for the demultiplexed sequences. In this case it should be the demultiplexed seqs file
# -D tells the program to catch all of the discarded reads to a file


start="Barcode\tFilename"; end="^\s*$"; sed -n "/$start.*/,/$end/{/$start.*/b;/$end/b;p}" demultiplexed_seqs_$4/process_radtags.log | \
        sed -e 's/\t/,/g' > demultiplexed_seqs_$4/process_radtags.csv
		
		
		

