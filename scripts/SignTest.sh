## Summary: Performs a sign test of base file against one or multiple external files based on clumped sumstats.
## Author: KLP
## Date: 08/18


#!/bin/sh
#$-S /bin/sh

#$ -V

#$ -pe smp 8

#$ -l h_vmem=16G
#$ -l h_rt=72:00:00

#$ -m be

export MKL_NUM_THREADS=8
export NUMEXPR_NUM_THREADS=8
export OMP_NUM_THREADS=8

###        Results file contains
###        1) The number of independent SNPS at each p-thershold tested in the base file
###        2) The proportion of SNPS shared at each threshold between the base and each target file provided
###        3) Whether this is significantly different from what would be predicted under the null

## Set working directory for source scripts

DIR=$(dirname $(readlink -f '$0'))

## call in source scripts 

source DIR/getcol.sh
source DIR/usage.sh


### declarations - basic argument parsing

Options=$@  ## Collect all arguments from the command line into a single array "Options" - ie all options expand to be contained within quotes
  set -f; arr=($Options); set +f   ## Convert these into an array
Optnum=$#   ## Collect the number of positional arguments entered
  
## Declarations
base=empty
target=empty
out=empty
r=0.01
k=3000
p='5.10e-8 5.10e-6 5.10e-4 5.10e-2 5.10e-1'
v='no'
s='no'
c='no'
facet_names=empty

## If there are no options then exit 

if [ $Optnum -eq 0 ]
  then 
     _usage
  exit 1
fi


printf '\n ## Sign test pipeline activated'
printf '\n'
#printf "Total number of argument provided: " $Optnum


## Parse command line flags with getopts 


while getopts 'b:t:o:p:r:k:shvc' OPTION
do
  case "$OPTION" in
  b  ) base="$OPTARG"      ;;
  t  ) target="$OPTARG"    ;;
  o  ) out="$OPTARG"       ;;
  p  ) p="$OPTARG"         ;;
  k  ) k="$OPTARG"         ;;
  r  ) r="$OPTARG"         ;;
  s  ) s='yes'             ;;
  c  ) c='yes'             ;;
  v  ) v='yes'             ;;
  h  ) _usage              ;;
  ? ) _usage               ;;
esac
done

## Check default flags are included

if [ "$target" = "empty" ] || [ "$out" = "empty" ]  || [ "$base" = "empty" ] 
then
  printf 'You are missing default arguments. Use -h to check usage' 
exit 1
fi

printf 'Sign tests will be performed against:\n' 
printf ${base}
printf '\n\nUsing target file(s)\n' 
echo $target
printf '\n\nResults will be saved to output file(s)\n'
printf ${out}
printf '\n\n'


### turn any possible list variables (pthresh and target files) into an array, and get length for later use.

tarray=($target)
parray=($p)


lentar=${#tarray[@]}
lenp=${#parray[@]}
    
    
### Get output names and paths
    
# base file
bname=$(basename $base)
# outpath
odir=$(dirname $out)
    
    
### Set variable names for all target files.

for n in $(seq 1 $lentar)
do
  declare "t_$n"="$(basename ${tarray[$n-1]})"
done

    
    
  ## If Verbose flag is set, warn about default flag changes 

count=0
pc=empty
kc=empty
rc=empty

if [ $c == 'yes' ]
then
  while [ $count -le $(( $Optnum * 2 )) ]
  do
    for x in $(seq 0  $(( $Optnum * 2 )) )
    do 
    (( count++ ))
    i=${arr[$x]}
    if [ "$i" == "-k" ] && [ "$kc" !=  "done" ]
    then 
      declare kc='done'
      read -p 'You are changing the default clumping window from 3000kb. Are you sure? (y or n) ' uservar  
      if [ $uservar == 'y' ]
      then
        printf '\nOK.  Clumping will be performed with a window of ' 
        echo ${arr[$((x+1))]} 'kb'
        printf '\n\n'
      else
          printf '\nOk. Exiting now. Please remove this flag and run script again\n'
        exit 1
       fi

    elif [ "$i" == "-r" ] && [ "$rc" != "done" ]
    then 
      declare rc='done'
      read -p 'You are changing the default R2 from 0.01. Are you sure? (y or n) ' uservar  
      if [ $uservar == 'y' ]
      then
        printf '\nOK. Clumping will be performed with an r2 of\n' 
        echo ${arr[$((x+1))]} 
        printf '\n\n'

      else
        printf 'Ok. Exiting now. Please remove this flag and run script again'
      exit 1
     fi

    elif [ "$i" == "-p" ] &&  [ "$pc" != "done" ]
    then 
      declare pc='done'
      read -p 'You are changing the default p thresholds from 5.10e-8, 5.10e-6, 5.10e-4, 5.10e-2, 5.10e-1, and 1. Are you sure? (y or n) ' uservar  
      if [ $uservar == 'y' ]
      then
        printf '\nOK. Sign tests will be run at your designated P-thresholds:\n'
        echo $p
        printf '\n\n'
       else
          printf '\nOk. Exiting now. Please remove this flag and run script again\n'
       exit 1
    fi
fi
done
done
fi


if [ $s == 'yes' ]
then
printf 'p=1 clumped base file will be saved to ' 
echo $(dirname $out)/Clumped.P1
printf '\n'
fi


## Perform clumping on the base file. 

if [ $v == 'yes' ]
then
printf 'Performing clumping on ' 
echo $bname ' using the following parameters: ' 
printf '\n' 
printf 'p1 & p2 == 1\nr2 == ' 
echo $r 'clumping window =' $k 'kb'
printf '\n\n'

else
  printf 'Beginning clumping...'
fi


for i in {1..22}
do

/mnt/lustre/groups/ukbiobank/Edinburgh_Data/Software/plink \
--bfile /mnt/lustre/groups/ukbiobank/Edinburgh_Data/Resources/1KG/1KG_Phase3/1KG_Phase3.chr$i.CLEANED.EUR \
--clump $base \
--clump-kb $k \
--clump-p1 1 \
--clump-p2 1 \
--clump-r2 $r \
--clump-range /mnt/lustre/groups/ukbiobank/Edinburgh_Data/Resources/glist-hg19 \
--out $(dirname $out)/$bname.CLUMPED.$i

done

## Merge the clumped files, then remove the individual files.

if [ $v == 'yes' ]
then
  printf '\n\nClumping complete.\n\nConcatenating chromosome files and removing individually clumped files\n'
else
  printf '\n\nClumping complete\n\n'
fi

cat $(dirname $out)/$bname.CLUMPED.* >> $(dirname $out)/$bname.WG.clump

rm $(dirname $out)/*CLUMPED*

  ## Create p-thresholded clumped files based on default or user input.

  ## Only handles RSID format at the moment because of code below:
  ## P==1 (always included)

  awk 'NR>1{if ($3 != "") print $3}' $(dirname $out)/$bname.WG.clump | sort -k 1,1 | uniq > $(dirname $out)/${bname}_P1.snplist ; sed -i '/^\(rs\)/!d' $(dirname $out)/${bname}_P1.snplist; sed -i -e '1iSNP' $(dirname $out)/${bname}_P1.snplist


## Loop through default or user provided p thresholds and create snplits.

for thresh in ${parray[@]}
do
  awk -v a=${thresh} '{if ($5 < a && $3 != "") print $3}' $(dirname $out)/$bname.WG.clump | sort -k 1,1 | uniq > $(dirname $out)/${bname}_P${thresh}.snplist

  wc=($( wc -l $(dirname $out)/${bname}_P${thresh}.snplist ))

if [ $wc -eq 0 ]
then
  echo -e 'SNP' > $(dirname $out)/${bname}_P${thresh}.snplist
else
  sed -i '/^\(rs\)/!d' $(dirname $out)/${bname}_P${thresh}.snplist
  sed -i -e '1iSNP' $(dirname $out)/${bname}_P${thresh}.snplist 
fi

done


if [ $v == 'yes' ]
then
  printf "\n### \n\nSNP lists created for independent SNPS at genome-wide significant p thresholds of " 
  echo ${parray[@]}
  printf ' ###\n\n'
 fi


## Save or remove clumped file

if [ $s == 'yes' ]
then
  mkdir $odir/Clumped.P1
  mv $odir/$bname.WG.clump $odir/Clumped.P1
  printf $odir/${bname}.WG.clump  
  printf 'created and moved to ' 
  echo ${odir}/Clumped.P1  
else
rm bname.WG.clump
fi


## Merge base and target sumstats - retaining direction of effect statistic

## retain only SNP and effect columns for all files.

## Select and rename columns using getcol.sh function


if [ $v == 'yes' ]
then
  printf "\nGathering SNP and effect columns from your base file.\n\n" 
fi

getColumns $base 

# move the new basefile to the out directory.

mv $(dirname $base)/$(basename $base).short $(dirname $out)/$(basename $base).short 

if [ $v == 'yes' ]
then
  printf "\nGathering SNP and effect columns from your target files.\n\n" 
fi

## targets

getColumns ${tarray[@]}

for f in ${tarray[@]};do
  mv $(dirname $f)/$(basename $f).short $(dirname $out)/$(basename $f).short
done

### sort files

awk 'NR<2{print$0;next} {print $0 | "sort -k 1,1"}' ${odir}/${bname}.short  > ${odir}/${bname}.sorted

for x in $(seq 1 $lentar)
do
  awk 'NR<2{print$0;next} {print $0 | "sort -k 1,1"}' ${odir}/$(basename  ${tarray[$x-1]}).short  > ${odir}/$(basename  ${tarray[$x-1]}).sorted
done

## remove the short / named files. 

rm ${odir}/*.short 

### create merged sumstat files containing SNP and effect for each p-threshold

## Ensure P1 is in the array at this point. 

parray+=(1)

for thresh in ${parray[@]}
do
  join ${odir}/${bname}_P${thresh}.snplist ${odir}/${bname}.sorted > ${odir}/${bname}_P${thresh}.sign

  for x in $(seq 1 $lentar) 
  do
    join ${odir}/${bname}_P${thresh}.sign ${odir}/$(basename  ${tarray[$x-1]}).sorted > temp && mv temp ${odir}/${bname}_P${thresh}.sign
  done
done


## Then remove the shorter, sorted sumstat files

rm ${odir}/*.sorted

## Set the number of fields of the combined files as a variable

nfiles="$(awk '{print NF}' ${odir}/${bname}_P1.sign | head -n 1)" 

echo "The number of target samples to compare against base: " $(( $nfiles -2 ))

## Set the number of total SNPS in each file
## need to remove any punctuation from p thesholds before can be used as a variable name

## create an associative array of total SNPs at each threshold

declare -A TOT

for thresh in ${parray[@]}
do
  name="$(sed -e 's/[[:punct:]]//g' <<<${thresh})"
  eval TOT[$name]="$(head -n -1 ${odir}/${bname}_P${thresh}.sign | wc -l )"
done

## Perform the sign test between all columns.

printf '\n## Sign Test Results ##\n\n'

## create an associative array of total matches for each column + threshold ( pthresh+column name == array key.)

declare -A Results

for thresh in ${parray[@]}
do
  for col in $(seq 3 $(( $nfiles )))
  do  
    name="$(sed -e 's/[[:punct:]]//g' <<<${thresh})"
    sample="$(head -n 1 ${odir}/${bname}_P${thresh}.sign | awk -v field=$col '{print $field}' - )"

    Results[${name}_${sample}]="$(awk -v n=$col '{if (($2 > 0 && $n > 0) || ($2 < 0 && $n < 0)) print 1}' ${odir}/${bname}_P${thresh}.sign | head -n -1 | wc -l)" 

  done
done

### Now summarise the result - make an array and csv of these 

echo "pthreshold, Base_sample, Target_sample, Total_SNPs, Total_Shared, Proportion, Binomial_test" >> ${out}_results.csv

for thresh in ${parray[@]}
do
  echo "####### RESULTS at p threshold " $thresh "     ########"

  printf '\n'
  for col in $(seq 3 $(( $nfiles )))
  do
    name="$(sed -e 's/[[:punct:]]//g' <<<${thresh})"
    sample="$(head -n 1 ${odir}/${bname}_P${thresh}.sign | awk -v field=$col '{print $field}' - )"

    echo "#### Comparing " $sample "column with the basefile" $bname " ####"
    printf '\n\n'

    tot="${TOT[$name]}"
    match="${Results[${name}_${sample}]}"
    prop="$(awk -v mat=$match -v tot=$tot \
    'BEGIN{print mat/tot;}')"

    echo $match "SNPS share the same direction out of a total of " $tot " shared SNPS at this threshold"
    printf '\n'
    echo "Proportion of SNPS acting in the same direction:" $prop
    printf '\n\n'

    echo "$thresh, ${bname}, $sample, $tot, $match, $prop, " >> ${out}_results.csv

  done


  printf "    ~ #########  ~     \n\n\n"

done

### Finish up the r results table and binomial test in R

  Rscript DIR/results.R ${out}_results.csv ${odir}/

  mv ${odir}/sign.table.csv ${odir}/$(basename $out)_results.csv
  mv ${odir}/stacked.bar.pdf ${odir}/$(basename $out)_stacked.bar.pdf
  rm ${bname}_results.csv


if [ $v == 'yes' ]
  then
    printf '\n\n###############################\n\n'
    echo 'Results saved to ' ${odir}/$(basename $out)_results.csv
    printf '\n For results of two-sided exact binomial test, see results table.'
    printf '\n\n Sign test completed.... cleaning folders...\n\n'
    rm ${odir}/*.sign
    rm ${odir}/*.snplist
    printf '\n\n Folder clean. Script completed\n\n'
    printf '\n\n Goodbye.\n\n'
    printf '\n\n###############################\n\n'
  else 
    rm ${odir}/*.sign
    rm ${odir}/*.snplist
    printf '\n\n###############################\n\n'
    echo 'Results saved to ' ${odir}/${bname}_results.csv
    printf '\n For results of two-sided exact binomial test, see results table.'
    printf '\n\n###############################\n\n'
fi

