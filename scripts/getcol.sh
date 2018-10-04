#!/bin/sh
#$-S /bin/sh
#$ -V
#$ -l h_vmem=4G
#$ -l h_rt=01:00:00

getColumns () 
{

  local cols=$@                                        # collect all files
  declare -a snp_col=('rsid' 'SNP')                    # set up SNP and effect arrays
  declare -a eff_col=('beta' 'Effect' 'OR' 'Z')         
  
  for file in ${cols[@]}; do                           # loop through files.
  if awk '{exit !/\t/}' $file ; then sep='\t'; else sep=[:space:]; fi  ## get the file seperator
    for n in "${snp_col[@]}";do                        # Get the column index for SNP columns and save as variable  
        local WORD=${n}
        local a=$(head -n 1 $file | tr $sep '\n' | grep -n -i "\b${WORD}\b" | tr -dc '0-9')
        
        if [ $a > 0 ]
        then 
          break
        else
        continue
        fi
    done
      
    for n in "${eff_col[@]}";do                        # Get the column index for SNP columns and save as variable  
        local WORD=${n}
        local b=$(head -n 1 $file | tr $sep '\n' | grep -n -i "\b${WORD}\b" | tr -dc '0-9')
        
        if [ $b > 0 ]
        then 
          break
        else
        continue
        fi
    done
    
    awk -v a=$a -v b=$b '{print $a,$b}' $file > $(dirname $file)/$(basename $file).short    # cut columns
    sed -i -e "1s/$WORD/Effect.$(basename $file)/gI" $(dirname $file)/$(basename $file).short
    
  done
  return

}
