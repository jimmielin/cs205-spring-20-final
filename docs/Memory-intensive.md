# Scientific Problems 
STILT, the Stochastic Time-Inverted Lagrangian Transport model, is a Lagrangian particle dispersion model (LPDM) for atmospheric transport. STILT allows us to track particles (receptors) of interest backward in time and get the footprints of the receptors. In a flight campaign, where we fly an airplane and continuously measure components of the atmosphere, STILT allows us to follow the receptors of interest that we detected during the flight. As a result, we know where those receptors come from and better understand spatial components of the atmosphere.  
Although STILT has been parallelized via Slurm, running STILT for many receptors still takes a lot of time. For example, for one flight, we would want to run at least 600 receptors 24 hours backward in time. This would take at least 20 hours. This is only for one meteorological product. If we want to use different MET datasets (normally we do in order to get an ensemble of the results), we have to multiply that number by the number of MET datasets. 
For our 205 final project, we would like to accelerate the process using (i) mpi and (ii) available tools on public clouds. 

The following guide shows a small chunk of the above mentioned work. The real case would have 600 receptors. lt would take 20 hours to complete the simulation on Cannon.  

## Does STILT actually copy the MET data to every single node?? 

  * Follow How to run STILT on Cannon section for basic STILTS.  
    * if (!require('devtools')) install.packages('devtools')
    * devtools::install_github('benfasoli/uataq')
    * uataq::stilt_init('myproject')
    * Option 3
    * If you can’t install packages, make sure that you have 
* export R_LIBS_USER=$HOME/apps/R_version:$R_LIBS_USER 
* In the directory that you installed R (the one that you can see ‘myproject’), copy HundredReceptors.RData and past the file to that directory. For me, it is /n/holyscratch01/wofsy_lab/chulakadabba/
This .RData has the lat/lon/altitude of all the receptors of interest (100 in total).
You can read the .RData file easily by (i) run R, (ii) inside R, load(‘HundredReceptors.RData’), (iii) ls() [you would see receptors], (iv) type receptors [will see those 100 receptors]. 
Inside ‘myproject’, there is a folder ‘r’. Inside the folder ‘r’, there is a script called “run_stilt.r”. Copy run_stilt_4_8_2020.r to the same folder as run_stilt.r.
Change line 7 to your directory that you installed R.  
project <- 'myproject' #you do not have to name your working directory myproject… this is just a default name from the tutorial. 
stilt_wd <- file.path('/n/holyscratch01/wofsy_lab/chulakadabba/', project)
You can change the number of particles/nodes/cores etc inside the script 
NOTE: you should change the time to be 4:00:00 ++ 
Don’t forget to link met_directory to the place you keep your MET files. For example   met_directory <- file.path('/n/holyscratch01/linz_lab/CS205/METFILES')
The following is the domain of the simulation lat: [-74.8, -71.0], lon: [39.7, 42.1] (New York City area) Date of interest: March 1st, 2019. 
We used The Global Forecast System (GFS) model outputs and ran STILT backward in time for 24 hours to see where the receptors came from.  

If you look at myproject/out/, there are three sub directories there: by-id  footprints  particles [by-id is the one that actually stores things, the rest just have links to by-id]
If you look inside by-id, there should be a bunch of folders  
Inside each folder, you should see (i) .nc file [gridded outputs], (ii) .rds file [ungridded outputs], (iii) the rest [the the following screenshot]. 
To visualize the .nc output file, you can use my ipython notebook (Read_NC_files.ipynb) → not well written, but you should get the idea. 


Hopefully, there is no error file inside the folder because, if you did, it means that the model did not run properly.




##Domain of the simulation
New York City area 
lat: [-74.8, -71.0], lon: [39.7, 42.1] 
Date of interest: March 1st, 2019.
24 Hours 

Below == stilt output (-24) overlay on top of Google Map. 
600 particles 
