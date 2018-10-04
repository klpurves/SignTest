
#!/bin/sh
#$-S /bin/sh
#$ -V
#$ -l h_vmem=4G
#$ -l h_rt=01:00:00
#$ -m be

function _usage()
{
  ###### U S A G E : Help and ERROR (invalid options provided) ######
  cat <<'EOF' 
  
  Sign test performed comparing target file(s) to a clumped base file. 
  
  Usage: 
    
    Your base and target column names should not containt punctuation! (i.e. 'P' is acceptable 'p-value' or 'p.value' is not)
  
  Required Input:
  -b Summary stastics for the base analysis. Ensure file contains a SNP id column called either SNP or rsid and an effect column named either Effect, OR or Beta.
  -t Summary statistics of target file or files to compare agaisnt the base file. Ensure file(s) contains a SNP id column called either SNP or rsid and an effect column named either Effect, OR or Beta. Multiple target files must be presented in a space seperated list, like so "file1 file2 file3..."
  -o Path and name of the results file
  
  Optional input:
  -p P-thresholds for sign tests (p == 1 is always tested). Defaults to 510-8, 510-6, 510-4, 510-2, 510-1 if left blank. If multiple thresholds are provided, these must be presented in a space seperated list, like so "p1 p2 p3...". 
  -k kb window for clumping. Defaults to 3000 if left blank.
  -r R2 threshold for clumping. Defaults to 0.01 if left blank.
  -s If set, P1 clumped base file will be saved in a new folder (set to the provided outfile directory ./Clumped.p1)
  -v Verbose. Include this for more detailed output.
  -c Check parameters. This will include flag checks for any changes to default settings. Do not include this flag if submitting the job using qsub or similar.
EOF
}
