# SignTest
Bash package to compare direction of SNP effects across samples at different p-thresholds.

Use -h for usage


Steps:   
i. Clump base file (using 1000 genomes as reference)  
ii. Create SNPlists at different p-thresholds based on clumped file  
iii. Merge target (replication) samples with base at different thresholds so only independent SNPs present in base sample.
iv. Perform SNP test
v. Perform exact binomial test (probability of 0.5, two-sided)

Output:     
i. Table containing total indepedndent SNPS at each threshold for each sample against base, total shared SNPS, proportion shared SNPS, Binomial exact p-value.     

ii. Stacked bar plot showing proportion of SNPs shared at each p-threshold for each target/base comaprison.

Optional output: Clumped base file (use - s flag to retain this file)

