# STILT R Executable
# For documentation, see https://uataq.github.io/stilt/
# Ben Fasoli

# User inputs ------------------------------------------------------------------
project <- 'myproject'
stilt_wd <- file.path('/n/holyscratch01/wofsy_lab/chulakadabba/', project)
output_wd <- file.path(stilt_wd, 'out')
lib.loc <- .libPaths()[1]

# Parallel simulation settings
n_cores <- 2
n_nodes <- 4

slurm   <- n_nodes > 1
slurm_options <- list(
  time      = '54:00:00',
  account   = 'cs205',

  partition = 'shared',

#   mem = 30000
  mem = 80000
#Rule of thumb is double the met cost (3.3 Gb/6hr for HRRR, 3300 MB
#so 16,000 = appropriate for 2.5 HRRR files)
        #BUT memory plays a role in how demanding your being too, so balance it out a bit

)

load(file.path(dirname(stilt_wd),"HundredReceptors.RData"))
#dirname = name of parent (can be iterated)


# Footprint grid settings, must set at least xmn, xmx, ymn, ymx below
hnf_plume <- T
projection <- '+proj=longlat'

smooth_factor <- 1
time_integrate <- F

#ACES domain with bounds still lat/long basesd on the stilt help
#lat/long domain
xmn <- -74.8
xmx <- -71
ymn <- 39.7
ymx <- 42.1
xres <- 0.01
yres <- xres

# Meteorological data input
met_directory  <- file.path('/n/holyscratch01/linz_lab/CS205/METFILES') 
#met_file_format <- '%Y%m%d.%Hz.hrrra'
#HRRR
#met_file_format <- '%Y%m%d_hysplit.t00z.namsa'
#NAMS
#met_file_format <- '%Y%m%d_nam12'
#NAM12
met_file_format <- '%Y%m%d_gfs0p25'
#GFS
#met_file_format <- 'NARR%Y%m'
#NARR
#met_file_format <- '%Y%m%d_gdas0p5'
#GDAS
n_met_min       <- 1



# Model control
n_hours    <- -24
numpar     <- 100
rm_dat     <- T
run_foot   <- T
run_trajec <- T
#timeout    <- 3600 timeout has been adjusted to 2.5 hours
timeout    <- 9000
varsiwant  <- c('time', 'indx', 'long', 'lati', 'zagl', 'sigw', 'tlgr', 'zsfc',
                'icdx', 'temp', 'samt', 'foot', 'shtf', 'tcld', 'dmas', 'dens',
                'rhfr', 'sphu', 'solw', 'lcld', 'zloc', 'dswf', 'wout', 'mlht',
                'rain', 'crai', 'pres')

# Transport and dispersion settings
conage      <- 48
cpack       <- 1
delt        <- 1
dxf         <- 1
dyf         <- 1
dzf         <- 0.1
emisshrs    <- 0.01
frhmax      <- 3
frhs        <- 1
frme        <- 0.1
frmr        <- 0
frts        <- 0.1
frvs        <- 0.1
hscale      <- 10800
ichem       <- 0
iconvect    <- 1
initd       <- 0
isot        <- 0
kbls        <- 1
kblt        <- 1
kdef        <- 1
khmax       <- 9999
kmix0       <- 250
kmixd       <- 3
kmsl        <- 0
kpuff       <- 0
krnd        <- 6
kspl        <- 1
kzmix       <- 1
maxdim      <- 1
maxpar      <- min(10000, numpar)
mgmin       <- 2000
ncycl       <- 0
ndump       <- 0
ninit       <- 1
nturb       <- 0
outdt       <- 0
outfrac     <- 0.9
p10f        <- 1
qcycle      <- 0
random      <- 1
splitf      <- 1
tkerd       <- 0.18
tkern       <- 0.18
tlfrac      <- 0.1
tratio      <- 0.9
tvmix       <- 1
veght       <- 0.5
vscale      <- 200
w_option    <- 0
zicontroltf <- 0
ziscale     <- rep(list(rep(0.8, 24)), nrow(receptors))
z_top       <- 25000

# Transport error settings
horcoruverr <- NA
siguverr    <- NA
tluverr     <- NA
zcoruverr   <- NA

horcorzierr <- NA
sigzierr    <- NA
tlzierr     <- NA

# Interface to mutate the output object with user defined functions
before_trajec <- function() {output}
before_footprint <- function() {output}


# Startup messages -------------------------------------------------------------
message('Initializing STILT')
message('Number of receptors: ', nrow(receptors))
message('Number of parallel threads: ', n_nodes * n_cores)


# Source dependencies ----------------------------------------------------------
setwd(stilt_wd)
source('r/dependencies.r')


# Structure out directory ------------------------------------------------------
# Outputs are organized in three formats. by-id contains simulation files by
# unique simulation identifier. particles and footprints contain symbolic links
# to the particle trajectory and footprint files in by-id
system(paste0('rm -r ', output_wd, '/footprints'), ignore.stderr = T)
if (run_trajec) {
  system(paste0('rm -r ', output_wd, '/by-id'), ignore.stderr = T)
  system(paste0('rm -r ', output_wd, '/particles'), ignore.stderr = T)
}
for (d in c('by-id', 'particles', 'footprints')) {
  d <- file.path(output_wd, d)
  if (!file.exists(d))
    dir.create(d, recursive = T)
}


# Met path symlink -------------------------------------------------------------
# Auto symlink the meteorological data path to the user's home directory to
# eliminate issues with long (>80 char) paths in fortran
if ((nchar(paste0(met_directory, met_file_format)) + 2) > 80) {
  met_loc <- file.path(path.expand('~'), paste0('m', project))
  if (!file.exists(met_loc)) invisible(file.symlink(met_directory, met_loc))
} else met_loc <- met_directory


# Run trajectory simulations ---------------------------------------------------
stilt_apply(FUN = simulation_step,
            slurm = slurm,
            slurm_options = slurm_options,
            n_cores = n_cores,
            n_nodes = n_nodes,
            before_footprint = list(before_footprint),
            before_trajec = list(before_trajec),
            conage = conage,
            cpack = cpack,
            delt = delt,
            emisshrs = emisshrs,
            frhmax = frhmax,
            frhs = frhs,
            frme = frme,
            frmr = frmr,
            frts = frts,
            frvs = frvs,
            hnf_plume = hnf_plume,
            horcoruverr = horcoruverr,
            horcorzierr = horcorzierr,
            ichem = ichem,
            iconvect = iconvect,
            initd = initd,
            isot = isot,
            kbls = kbls,
            kblt = kblt,
            kdef = kdef,
            khmax = khmax,
            kmix0 = kmix0,
            kmixd = kmixd,
            kmsl = kmsl,
            kpuff = kpuff,
            krnd = krnd,
            kspl = kspl,
            kzmix = kzmix,
            maxdim = maxdim,
            maxpar = maxpar,
            lib.loc = lib.loc,
            met_file_format = met_file_format,
            met_loc = met_loc,
            mgmin = mgmin,
            n_hours = n_hours,
            n_met_min = n_met_min,
            ncycl = ncycl,
            ndump = ndump,
            ninit = ninit,
            nturb = nturb,
            numpar = numpar,
            outdt = outdt,
            outfrac = outfrac,
            output_wd = output_wd,
            p10f = p10f,
            projection = projection,
            qcycle = qcycle,
            r_run_time = receptors$run_time,
            r_lati = receptors$lati,
            r_long = receptors$long,
            r_zagl = receptors$zagl,
            random = random,
            rm_dat = rm_dat,
            run_foot = run_foot,
            run_trajec = run_trajec,
            siguverr = siguverr,
            sigzierr = sigzierr,
            smooth_factor = smooth_factor,
            splitf = splitf,
            stilt_wd = stilt_wd,
            time_integrate = time_integrate,
            timeout = timeout,
            tkerd = tkerd, tkern = tkern,
            tlfrac = tlfrac,
            tluverr = tluverr,
            tlzierr = tlzierr,
            tratio = tratio,
            tvmix = tvmix,
            varsiwant = list(varsiwant),
            veght = veght,
            vscale = vscale,
            w_option = w_option,
            xmn = xmn,
            xmx = xmx,
            xres = xres,
            ymn = ymn,
            ymx = ymx,
            yres = yres,
            zicontroltf = zicontroltf,
            ziscale = ziscale,
            z_top = z_top,
            zcoruverr = zcoruverr)

