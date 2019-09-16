#!/bin/bash

#SBATCH --job-name=
#SBATCH --time=96:00:00
#SBATCH -p normal
#SBATCH --nodes=1

#load software tools
module load stacks
module load parallel

#populate variables
DMXfiles=*_demultiplex.txt
preDMXfq=*_1.fq.gz
R1Ext=_1.fq.gz
R2Ext=_2.fq.gz
NumNestedDirs=echo "$DMXfiles" | tr "/" "\n" | head -n -1 | wc -l

if [ "$NumNestedDirs" == 0 ]; then

else
	
fi

# make a list of file name bases for the decode files
ls $DMXfiles | sed 's/_demultiplex.txt//g' > dmx.txt 

# make a list of fq file name bases
ls $preDMXfq | sed "s/$R1Ext//g" > fq.txt 

#create the directory where the demultiplexed sequences will go
parallel --no-notice mkdir demultiplexed_seqs_{} :::: dmx.txt

#demultiplx the fq files
parallel --no-notice --link "process_radtags -1 {1}$R1Ext -2 {1}$R2Ext -i gzfastq -b {2}_demultiplex.txt -r -e sbfI -o demultiplexed_seqs_{2} -D --bestrad" :::: fq.txt :::: dmx.txt


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
		
		
		


