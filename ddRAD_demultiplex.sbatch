#!/bin/bash

#SBATCH --job-name=
#SBATCH --time=96:00:00
#SBATCH -p normal
#SBATCH --nodes=1

#load software tools
module load stacks
module load parallel

#specify the file paths for the demultiplex and read 1 fq files and demultiplex the fq files in parallel
#example line to run this script:
#sbatch ddRAD_demultiplex.sbatch

#populate variables
DMXfiles=*_demultiplex.txt
FQfiles=*_1.fq.gz
R1Ext=_1.fq.gz
R2Ext=_2.fq.gz
dmxNumNestedDirs=$(echo "$DMXfiles" | tr "/" "\n" | head -n -1 | wc -l)
fqNumNestedDirs=$(echo "$FQfiles" | tr "/" "\n" | head -n -1 | wc -l)

if [ "$dmxNumNestedDirs" == 0 ]; then
	DMXpath="."
else
	DMXpath=$(dirname "$(echo "$DMXfiles")")
fi

if [ "$fqNumNestedDirs" == 0 ]; then
	FQpath="."
else
	FQpath=$(dirname "$(echo "$FQfiles")")
fi

# make a list of file name bases for the decode files
ls $DMXfiles | sed 's/_demultiplex.txt//g' | parallel -k --no-notice basename > dmx.txt 
NumDMX=$(wc -l dmx.txt | cut -d " " -f1)

# make a list of fq file name bases
ls $FQfiles | sed "s/$R1Ext//g" | parallel -k --no-notice basename > fq.txt
NumFQ=$(wc -l fq.txt | cut -d " " -f1) 

#check to make sure that there are the same number of demultiplex and fastq files
if [[ $NumFQ != $NumDMX ]]; then 
	echo There are $NumDMX demultiplex files and $NumFQ fastq files.  They should be equal.
	echo Exiting
	exit
fi

#create the directories where the demultiplexed sequences will go
parallel --no-notice mkdir demultiplexed_seqs_{} :::: dmx.txt

#demultiplx the fq files
parallel --no-notice --link "process_radtags -1 $FQpath/{1}$R1Ext -2 $FQpath/{1}$R2Ext -i gzfastq -b $DMXpath/{2}_demultiplex.txt -r -e ecoRI -o demultiplexed_seqs_{2} -D" :::: fq.txt :::: dmx.txt


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

QuantReadsRetained(){
	logPATH=$1
	RESULT=$(head -n 4 $logPATH | tail -n1)
	RetainedReads=$(echo $RESULT | cut -d " " -f2)
	TotalReads=$(echo $RESULT | cut -d " " -f6)
	echo -n ${logPATH}, && echo -n ${RetainedReads}, && echo $RetainedReads / $TotalReads | bc -l
}
export -f QuantReadsRetained
echo ""; echo "Reads Retained:"
echo PoolID,NumReadsRet,PropReadsRet
parallel --record-env
find . -name 'process*log' | parallel --env _ --no-notice "QuantReadsRetained {}"
