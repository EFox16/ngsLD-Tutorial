#!/bin/bash

/usr/bin/ms 40 1 -t 600 -r 600 1000000 > Test.txt

/usr/bin/msToGlf -in Test.txt -out Test -regLen 1000000 -singleOut 1 -depth 20 -err 0.01 -pileup 0 -Nsites 0

/usr/bin/Rscript -e 'cat(">reference\n",paste(rep("A",1e6),sep="", collapse=""),"\n",sep="")' > reference.fa 

/usr/bin/samtools faidx reference.fa

/usr/bin/angsd -glf Test.glf.gz -fai reference.fa.fai -nInd 20 -doMajorMinor 1 -doPost 1 -doMaf 1 -doGeno 32 -out Test_reads -isSim 1 -minMaf 0.05

zcat Test_reads.mafs.gz | cut -f 1,2 | tail -n +2 > Test_pos.txt
NS=`cat Test_pos.txt | wc -l`

mkdir TestResults
gunzip -f Test_reads.geno.gz

/usr/bin/ngsLD --geno Test_reads.geno --out TestResults/Test.ld --pos Test_pos.txt --n_ind 20 --n_sites $NS --verbose 1 --probs --max_kb_dist 1000 --min_maf 0.05 --rnd_sample 0.05

#~ python Fit_Exp.py --input_type FILE --input_name TestResults/Test.ld --data_type r2GLS --plot

