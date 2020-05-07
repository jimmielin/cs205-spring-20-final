#!/usr/bin/env Rscript
# STILT R CLI for multi-shot batch processing in cloud applications
#
# Haipeng Lin <hplin@seas.harvard.edu>
# based on the original STILT code by Ben Fasoli, STILT Project
#
#
# r/stilt_cli_multi.r stilt_wd=/shared/stilt_run_heavy recep_file_loc=/shared/HundredReceptors.RData recep_idx_s=5 recep_idx_e=10 met_dir=/shared met_file_format=%Y%m%d_gfs0p25 xmn=-74.8 xmx=-71 ymn=39.7 ymx=42.1 xres=0.01 yres=0.01 ncores=2

# Extract kv pairs for supplied arguments -------------------------------------
arg_strings <- commandArgs(trailingOnly = T)
args <- list()
for (arg in strsplit(arg_strings, '=', fixed = T)) {
    if (length(arg) == 1) {
        arg <- c(arg, 'NA')
    }
    args[arg[1]] <- paste(arg[2:length(arg)], collapse='=')
}

# Require the following arguments for multi-run:
#
#  ROOT DIRECTORY --
#   stilt_wd                Working directory containing exe, fortran, r
#
#  RECEPTOR INFORMATION --
#     You need to supply a receptors RData file at recep_file_loc
#     which contains the fields like so:
#           run_time            lati      long     zagl
#       1   2019-03-01 18:56:29 41.18988 -73.86909 318.8978
#       2   2019-03-01 18:56:39 41.18557 -73.87533 320.1119
#   recep_file_loc          Receptor RData file name (/fsx/receptors.RData)
#   recep_idx_s             Start from receptor index # (for batch par)
#   recep_idx_e             End   at   receptor index # (for batch par)
#
#  METEOROLOGY -- ONLY SUPPORTS FILES FOR NOW
#   met_dir  				Meteorology location directory
#   met_file_format  		Meteorology file format
#
#  DOMAIN CONFIGURATION
#   xmn, xmx, xres
#   ymn, ymx, yres
#
#  PARALLELIZATION CONFIGURATION
#   ncores                  # of CPUs to use in this run
#
vfy_args <- c("stilt_wd", "recep_file_loc", "recep_idx_s", "recep_idx_e",
	          "met_dir", "met_file_format",
	          "xmn", "xmx", "xres", "ymn", "ymx", "yres", "ncores")
if(!all(vfy_args %in% names(args))) { stop("Missing arguments for stilt_cli_multi.r. Verify.") }

# Show splash
message('Initializing STILT Multi-Batch Run')
message('STILT Root Dir: ', args["stilt_wd"])
message('Receptor File: ', args["recep_file_loc"])
message('Receptor Index S,E: ', args["recep_idx_s"], args["recep_idx_e"])
message('Met Dir: ', args["met_dir"])
message('Met File Format: ', args["met_file_format"])
message("Grid dim'l: xmn, xmx, xres = ", args["xmn"], " ", args["xmx"], " ", args["xres"])
message(" - ymn, ymx, yres = ", args["ymn"], " ", args["ymx"], " ", args["yres"])

# Validate parameters
stilt_wd    <- file.path(args["stilt_wd"])
output_wd   <- file.path(stilt_wd, 'out')
lib.loc     <- .libPaths()[1]

# Parallelization settings (single-node: slurm is NOT used)
n_cores     <- as.integer(args["ncores"])

# Read in the receptors in the "receptors" variable
load(file.path(args["recep_file_loc"]))

# Footprint grid settings
hnf_plume   <- T
projection  <- '+proj=longlat'
smooth_factor  <- 1
time_integrate <- F

xmn         <- as.numeric(args["xmn"])
xmx         <- as.numeric(args["xmx"])
ymn         <- as.numeric(args["ymn"])
ymx         <- as.numeric(args["ymx"])
xres        <- as.numeric(args["xres"])
yres        <- as.numeric(args["yres"])

# Meteorology fields
met_loc   <- args["met_dir"]
met_file_format <- args["met_file_format"]
# ?
n_met_min   <- 1

# Subsetting receptors:
#  receptors$lati[c(recep_idx_s:recep_idx_e)] ...
#  replace ziscale nrow(receptors) => recep_idx_e-recep_idx_s+1
# (hplin, 5/5/20)
recep_idx_s = as.integer(args["recep_idx_s"])
recep_idx_e = as.integer(args["recep_idx_e"])
# recep_run_time = receptors$run_time[c(recep_idx_s:recep_idx_e)]
# recep_lati = receptors$lati[c(recep_idx_s:recep_idx_e)]
# recep_long = receptors$long[c(recep_idx_s:recep_idx_e)]
# recep_zagl = receptors$zagl[c(recep_idx_s:recep_idx_e)]

recep_run_time = receptors[recep_idx_s:recep_idx_e,]$run_time
recep_lati = receptors[recep_idx_s:recep_idx_e,]$lati
recep_long = receptors[recep_idx_s:recep_idx_e,]$long
recep_zagl = receptors[recep_idx_s:recep_idx_e,]$zagl

############# BELOW MOSTLY ADAPTED FROM RUN_STILT.R #############
# Model control
n_hours    <- -24
numpar     <- 100
rm_dat     <- T
run_foot   <- T
run_trajec <- T
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
ziscale     <- rep(list(rep(0.8, 24)), length(recep_run_time))
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

# Startup messages
message('Initializing STILT')
message('Number of receptors: ', length(recep_run_time))
setwd(stilt_wd)
source('r/dependencies.r')

# Verify the output directory exists.
# The first batch job to do this wins.
for (d in c('by-id', 'particles', 'footprints')) {
  d <- file.path(output_wd, d)
  if (!file.exists(d))
    dir.create(d, recursive = T)
}

# Run simulations
stilt_apply(FUN = simulation_step,
            slurm = F,
            slurm_options = list(),
            n_cores = n_cores,
            n_nodes = 1,
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
            r_run_time = recep_run_time,
            r_lati = recep_lati,
            r_long = recep_long,
            r_zagl = recep_zagl,
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