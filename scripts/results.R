
# Run binomial tests, save table and create plots

## Load packages

library(data.table)
library(ggplot2)
library(dplyr)

# Collect command line arguments

args=commandArgs(TRUE)
file=args[1]
path=args[2]

# Read in results csv

dat<- fread(file)

# Ensure all fields are numeric

dat$Total_SNPs <- apply(dat[,4],1,as.numeric)
dat$Total_Shared <- apply(dat[,5],1,as.numeric)
dat$Proportion <- apply(dat[,6],1,as.numeric)

# Perform binomial tests where possible (2 sided, binomial exact, null 0.5, conf level 0.95)

for (row in 1:dim(dat)[1]){
  if ((is.na(dat$Total_Shared[row]) | (dat$Total_Shared[row] == 0))){
    dat$Binomial_test[row] <- NA 
  } else {
    dat$Binomial_test[row] <- binom.test(x=dat$Total_Shared[row],n=dat$Total_SNPs[row],p=0.5,conf.level=0.95)$p.value
  }
}

# Order these by sample then p-thresholds

dat <- dat[order(dat$Target_sample,dat$pthreshold),]

# Save csv

write.csv(dat, paste(path,'sign.table.csv',sep='/'),quote=F,row.names=F)


## create a plot showing shared SNPs as a proportion of total SNPs for each target / base comparison

# Set Binomial test NA values to 1 so no sig flags are applied

dat$Binomial_test <- ifelse(is.na(dat$Binomial_test),1,dat$Binomial_test)

# Create total unsahred SNP column
dat$Total_Unshared <- dat$Total_SNPs - dat$Total_Shared

# Subset 
datp <- subset(dat,select=c('Base_sample','Target_sample','Proportion','pthreshold','Total_Shared','Total_Unshared','Binomial_test'))

# Melt dataframe for plotting
datm <- melt(datp,id.vars=c('Base_sample','Target_sample','pthreshold','Proportion','Binomial_test'))

# Order variable factor
datm$variable <- factor(datm$variable,levels=c('Total_Unshared','Total_Shared'))


## Create plot - use dplyr to flag and colour  significant results

plot <- 
## create variable flagging differing significant levels based on binomial test results 
datm %>%
      mutate(sig_flag = ifelse(datm$variable == "Total_Shared" & datm$Binomial_test <= 0.001, 'p<0.001',
                             ifelse(datm$variable == "Total_Shared" & datm$Binomial_test <= 0.005, 'p<0.005',
                             ifelse(datm$variable == "Total_Shared" & datm$Binomial_test <= 0.01, 'p<0.01',
                                    ifelse(datm$variable == "Total_Shared" & datm$Binomial_test <= 0.05, 'p<0.05',
                                           ifelse(datm$variable == "Total_Shared" & datm$Binomial_test > 0.005,'p>0.05','')))))) %>%
  
  ## Change the factor order to create approrpiate colour gradients later
  
  mutate(p.value = factor(sig_flag,levels = c("","p>0.05","p<0.05",'p<0.01',"p<0.005","p<0.001"))) %>%
  
  ## Create the ggplot
  
    ggplot(aes(x=as.factor(pthreshold),y=value))                              +
    geom_bar(aes(fill=p.value),
             stat='identity',position='fill')                                 +
             facet_grid(Base_sample ~ Target_sample)                          +
              xlab("p-threshold")                                             +
              ylab("Proportion of total SNPs shared")                         +
              theme(panel.border = element_blank(),
                    panel.grid = element_blank(),
                    strip.text = element_text(face='bold',
                                  size=12))                                   +
             geom_hline(yintercept=0.5,linetype="dashed",color="red")         +
             scale_fill_manual(breaks=c('p>0.05','p<0.05','p<0.01','p<0.005','p<0.001'),
                               values=c("azure3","#636363","#993399","#0000FF","#30D5C8","#E4FFFF"))
                               
pdf(paste(path,'stacked.bar.pdf',sep='/'),width=15)
plot
dev.off()
