# Running STILT on FASRC Cannon
This is the reference implementation.

## Environment setup
Load the required modules below:
```bash
module load netcdf/4.7.3-fasrc01 R/3.6.3-fasrc01 proj/5.0.1-fasrc01 gdal/2.3.0-fasrc01 gcc/7.1.0-fasrc01 udunits/2.2.26-fasrc01 geos/3.6.2-fasrc01
```

Reference module list:
```
[cs205u2038@boslogin03 cs205u2038]$ module list

Currently Loaded Modules:
  1) zlib/1.2.8-fasrc07     8) bzip2/1.0.6-fasrc01    15) R_packages/3.6.3-fasrc01  22) mpc/1.0.3-fasrc06
  2) szip/2.1-fasrc02       9) pcre/8.37-fasrc02      16) R/3.6.3-fasrc01           23) gcc/7.1.0-fasrc01
  3) hdf5/1.10.6-fasrc01   10) libtiff/4.0.9-fasrc01  17) proj/5.0.1-fasrc01        24) udunits/2.2.26-fasrc01
  4) netcdf/4.7.3-fasrc01  11) R_core/3.6.3-fasrc01   18) hdf/4.2.12-fasrc01        25) geos/3.6.2-fasrc01
  5) readline/6.3-fasrc02  12) gsl/1.16-fasrc02       19) gdal/2.3.0-fasrc01
  6) jdk/10.0.1-fasrc01    13) nlopt/2.4.2-fasrc01    20) gmp/6.1.2-fasrc01
  7) curl/7.45.0-fasrc01   14) libxml2/2.7.8-fasrc02  21) mpfr/3.1.5-fasrc01
```

## Configuring R
Install the modules into `$SCRATCH/cs205/$USER/rlibs` (this is a new directory, create it).

```R
if(!require('devtools')) install.packages('devtools', lib='/n/holyscratch01/cs205/cs205u2038/rlibs')
devtools::install_github('benfasoli/uataq', lib='/n/holyscratch01/cs205/cs205u2038/rlibs')
```
Use option 3.

