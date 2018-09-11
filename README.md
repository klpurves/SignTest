# SignTest
Bash package to compare direction of SNP effects across samples at different p-thresholds


Steps:   
i. Clump base file (using 1000 genomes as reference)  
ii. Create SNPlists at different p-thresholds based on clumped file  
iii. Merge target (replication) samples with base at different thresholds so only independent SNPs present in base sample.
iv. Perform SNP test
v. Perform exact binomial test (probability of 0.5, two-sided)

Output is a table containing:  total indepedndent SNPS at each threshold for each sample against base, total shared SNPS, proportion shared SNPS, Binomial exact p-value.

Optional output: Clumped base file.

