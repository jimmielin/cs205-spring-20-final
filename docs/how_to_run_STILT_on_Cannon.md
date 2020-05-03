# How to run STILT on Cannon 

MET file (20190301_gfs0p25) that I uploaded to our Google Drive folder. 
Follow the installation here  
if (!require('devtools')) install.packages('devtools')
devtools::install_github('benfasoli/uataq')
3
Option 3
Quick Start here
 Rscript -e "uataq::stilt_init('myproject')"
r/run_stilt.r
Rscript r/run_stilt.r
module load netcdf R proj/5.0.1-fasrc01 gdal/2.3.0-fasrc01 gcc/7.1.0-fasrc01 udunits/2.2.26-fasrc01 geos/3.6.2-fasrc01  
Run R (R version 3.5.1 (2018-07-02))
Run the run_stilt.r fille. 
You can obtain MET files from Gridded Data Archives (an example is here)
      
   Module avail R to search the available R package/ Odyssey document for modules to look at available R version  https://portal.rc.fas.harvard.edu/p3/build-reports/
(e.g. module load R/3.5.0-fasrc02 (Boer) R_core/3.5.1-fasrc01 (Ju), R_packages/3.5.1-fasrc01 )

What you have to change in run_stilt.r 

Pick the slurm config of your choice:
```
...
n_cores <- 1
n_nodes <- 300
slurm   <- n_nodes > 1
slurm_options <- list(
  time      = '01:00:00',
  partition = 'huce_cascade',
  mem = 35000
…
```
`load(file.path(dirname(stilt_wd),"STILT_file.Rdata"))`, where STILT_file to be the metfile of your choice in Rdata format. 
export R_LIBS_USER=$HOME/apps/3.5.1:$R_LIBS_USER
