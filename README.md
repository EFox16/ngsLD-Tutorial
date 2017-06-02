# ngsLD Tutorial

# Example Analysis
## 1. Generate a set of variable sites using ms (Hudson, 2002)
(http://home.uchicago.edu/rhudson1/source/mksamples.html)
	
	% ./ms 40 1 -t 600 -r 600 1000000 > Test.txt

This example will generate 1 data set of the variable sites for 1 megabase samples from 40 chromosomes (20 individuals). Theta `-t` is calculated as 4 * Mutation Rate (1.5x10^-8) * Population Size (10^4) * Number of Sites (10^6). Setting rho `-r` equal to theta will generate a human-like data set. This will generate a data set with typical properties of a population at constant size. This is the default scenario although expanding populations and bottleneck events can also be simulated. 

## 2. Use ANGSD (Korneliussen et al., 2014) to generate a genotype likelihood file (.glf) from the ms simulation
(http://www.popgen.dk/angsd/index.php/ANGSD, http://www.popgen.dk/angsd/index.php/MsToGlf)

	% ./msToGlf -in Test.txt -out Test -regLen 1000000 -singleOut 1 -depth 20 -err 0.01 -pileup 0 -Nsites 0

This example takes the variable sites from ms and creates a set of hypothetical reads covering them from which genotype likelihoods can be generated. In this case, the read depth is 20. `-in` specifies the ms input file, `-out` names the resulting glf file, `-regLen` is the length of the sequences being examined, and `-err` is the sequencing error rate (a value of 0.01 is fairly typical). A `-pileup` value of 0 sets the output format to GLF and a `-singleOut` value of 1 directs all the ouput to a single file. A `-Nsites` of 0 sets the output format to ms which matches the input format.

## 3. Use ANGSD and samtools (Handsaker et al., 2009) to fill in the non-variable sites to give a full genome sequence.
(http://samtools.sourceforge.net/)

	% ./Rscript -e 'cat(">reference\n",paste(rep("A",1e6),sep="", collapse=""),"\n",sep="")' > reference.fa 
	% ./samtools faidx reference.fa

This step creates a 'reference sequence' which ANGSD uses to establish relative position of the bases. The new file has the word 'reference' on the first line and is then full of the letter A repreated 10^6 times to match our 1 megabase sequence length. 

	% ./angsd -glf Test.glf.gz -fai reference.fa.fai -nInd 20 -doMajorMinor 1 -doPost 1 -doMaf 1 -doGeno 32 -out Test_reads -isSim 1 -minMaf 0.05

`-glf` provides the name of the input file while `-out` sets the name of the output file and `-fai` is the reference file just created. `-nInd` is the number of indiviuals simulated (20) which will be half of the number of samples (40) specified in ms for diploid organisms. `-doMajorMinor` tells the program to use the likelihoods in the input file to determine the major and minor alleles. The `-doMaf 1` option signals the major and minor allele frequencies are fixed and the `-minMaf` option will exclude sites where the minimum allele frequency is below the number provided. `-minMaf` is calculated by dividing the number of samples (40) by 2. `-doPost 1` signals to use the information on overall allele frequency when determining genotype likelihoods. Setting `-doGeno 32` means the posterior probabilities of all the potential genotypes will be printed in binary in the output file.    
`-isSim`?

## 4. Run ngsLD to calculate linkage disequilbrium measures for the pairs of SNPs

	% zcat Test_reads.mafs.gz | cut -f 1,2 | tail -n +2 > Test_pos.txt
	% NS=`cat Test_pos.txt | wc -l` 
	
This first step creates a position file from the new sequence generated for ngsLD to use a reference and stores the number of sites as the variable `NS`. 

	% mkdir TestResult
	% gunzip -f Test_reads.geno.gz
	% ./ngsLD --geno Test_reads.geno --out TestResult/Test.ld --pos Test_pos.txt --n_ind 20 --n_sites $NS --verbose 1 --probs --max_kb_dist 1000 --min_maf 0.05 --rnd_sample 0.05 --seed 1

Here a new directory is created for the final LD results and the input file in unzipped. `--geno` denotes the input file and the output is directed to the file specified by `>`. `--n_ind` is the number of individuals and `--n_sites` is the number of sites calculated in the prior step with `--pos` denoting the  position file created in that step. `--max_kb_dist 1000` means each of the SNPs will be checked against every other SNP for linkage even if they are at opposite ends of the megabase sequence. `--min_maf 0.05` executes a similar filtering as it did in previous steps and `--probs` signals the genotypes in the input file are probabilites. The size of the potential data file will be quite large for a megabase of sequence, random sampling using `--rnd_sample` can be useful. This will drastically cut down on the size of the file but will still reflect the pattern of LD along the sequence. The data was down-sampled to 5% in this example. 

## 5. Run curve fitting script on the LD data to visualise the pattern of LD

	% python Fit_Exp.py --input_type FILE --input_name TestResults/Test.ld --data_type r2GLS --plot

This step fits an exponential decay curve to plot of LD strength versus the distance between SNPs in the pair. `--input_type` and `--input_name` allow the user to choose which file or folder of files to analyse. The `--data_type` tag specifies which of the four LD measures ngsLD generates to use as the response variable. The `--plot` tag is optional and will output graphs of each data set when used.


# Citations

Li, H., Handsaker, B., Wysoker, A., Fennell, T., Ruan, J., Homer, N., Marth, G., Abecasis, G. and Durbin, R., 2009. The sequence alignment/map format and SAMtools. Bioinformatics, 25(16), pp.2078-2079.

Hudson, R.R., 2002. Generating samples under a Wright–Fisher neutral model of genetic variation. Bioinformatics, 18(2), pp.337-338.

T. S. Korneliussen, A. Albrechtsen, and R. Nielsen.  ANGSD: Analysis of next generation sequencing data. BMC Bioinformatics, 15(1):356, Nov. 2014. ISSN 1471-2105. doi: 10.1186/s12859-014-0356-4. URL http://www.biomedcentral.com/1471-2105/15/356/abstract
