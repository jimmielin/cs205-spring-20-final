# Running STILT on AWS - ParallelCluster

## Setting up AWS on ParallelCluster
* Log-in to AWS and choose the region you like. `us-east-1` (West Virginia) is most popular and thus expensive. I will use `us-east-2` (Ohio). Take note of the region you use.

* First create a EC2 key pair + IAM Access Key on AWS management console.
The key pair looks like `hplin_aws_cs205_us2.pem` (private key) and the access key is downloaded in `rootkey.csv`:
```
AWSAccessKeyId=AKIAxxxxxxxxxxxxxx
AWSSecretKey=yyyyyyyyyyyyy
```

* Download and setup [AWS CLI utilities](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html). Version 2 is entirely self-contained, which is nice.

Quick reference (may break in the future):
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
* Configure AWS CLI utilities with your credentials, using the `aws configure` command like so:
```
% aws configure
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxx
AWS Secret Access Key [None]: yyyyyyyyyyyyy
Default region name [None]: us-east-2
Default output format [None]: json
```

I'm using `us-east-2` because it is cheap. Choose a region that matches the one you did in the beginning of the document.

* Download and setup `AWS-ParallelCluster` [from here](https://docs.aws.amazon.com/parallelcluster/latest/ug/install.html):
```bash
pip3 install aws-parallelcluster --upgrade --user
```

See if you can access `pcluster` using `pcluster version`. If **not**, add it to your `PATH`. Linux instructions are:
```
export PATH="/home/$USER/.local/bin:$PATH"
```

Make sure `which pcluster` gives you the correct path to the executable, in my case `/home/jimmie/.local/bin/pcluster`.

* **Configure the `pcluster` stack before first run.** Read questions carefully, suggested answers are below. We are using `t3.xlarge` as master and `c5.4xlarge` as testing compute setups here, but you may want to check out the work to determine which set is best for you.

```
INFO: Configuration file /home/jimmie/.parallelcluster/config will be written.
Press CTRL-C to interrupt the procedure.


Allowed values for AWS Region ID:
...
14. us-east-2
...
AWS Region ID [us-east-1]: 14
Allowed values for EC2 Key Pair Name:
1. hplin_aws_cs205_us2
EC2 Key Pair Name [hplin_aws_cs205_us2]:
Allowed values for Scheduler:
...
3. slurm
...
Scheduler [sge]: 3
Allowed values for Operating System:
1. alinux
2. alinux2
3. centos6
4. centos7
5. ubuntu1604
6. ubuntu1804
Operating System [alinux]: 2
Minimum cluster size (instances) [0]:
Maximum cluster size (instances) [10]:
Master instance type [t2.micro]: t3.xlarge
Compute instance type [t2.micro]: c5.4xlarge
Automate VPC creation? (y/n) [n]: n
Allowed values for VPC ID:
1. vpc-aefc2dc5 | 3 subnets inside
VPC ID [vpc-aefc2dc5]:
Automate Subnet creation? (y/n) [y]:
Allowed values for Network Configuration:
1. Master in a public subnet and compute fleet in a private subnet
2. Master and compute fleet in the same public subnet
Network Configuration [Master in a public subnet and compute fleet in a private subnet]:
Creating CloudFormation stack...
Do not leave the terminal until the process has finished
```

**Note on master node size:** Use `t3.xlarge` at initialization simply because it will allow you to install the software environment faster. Once that is set up you can feel free to switch to `t3.micro` or `t2.micro` covered by the free tier - it will be plenty!

You will be able to find the finished configuration file, `~/.parallelcluster/config` looking something like this:
```
[aws]
aws_region_name = us-east-2

[global]
cluster_template = default
update_check = true
sanity_check = true

[aliases]
ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}

[cluster default]
key_name = xxxxxxxx
base_os = alinux2
scheduler = slurm
compute_instance_type = c5.4xlarge
maintain_initial_size = true
vpc_settings = default

[vpc default]
vpc_id = vpc-aefc2dc5
master_subnet_id = subnet-xxxxxxxx
compute_subnet_id = subnet-xxxxxxxy
use_public_ips = false
```

## Creating and setting up your own Parallel Cluster
### Creating the cluster
* **Create your cluster using:** where `cs205-test1` is the name of your cluster.
```
pcluster create cs205-test1
```

```diff
- It goes without saying, but please be reminded to terminate your cluster  -
- at end of your work, otherwise you WILL BE CHARGED FOR THE IDLE USAGE!    -
```

* Once created, **login** using `pcluster ssh cs205-test1`. **You may have to specify your SSH key manually**.

### BONUS: Enable slurm accounting
If you want to measure task running time (like we want to for the project), you have to enable slurm accounting manually in the slurm daemon on AWS-ParallelCluster, as by default it is not used.

A quick-and-dirty setup without a database, using a textfile, is simply to edit `/opt/slurm/etc/slurm.conf` and configure accounting like so:
```
# ACCOUNTING                                                                                                            JobAcctGatherType=jobacct_gather/linux                                                                                  JobAcctGatherFrequency=30                                                                                               #                                                                                                                       AccountingStorageType=accounting_storage/filetxt
#AccountingStorageHost=
AccountingStorageLoc=/opt/slurm/slurmacct
```

Then make sure you have that accounting file available:
```bash
sudo touch /opt/slurm/slurmacct
sudo chown slurm:slurm /opt/slurm/slurmacct
sudo systemctl start slurmctld
```

### Setting up software environment
* We will use [spack](https://github.com/spack/spack), an awesome software manager for HPC. Get spack and `python3`:
```bash
git clone https://github.com/spack/spack.git
echo 'export PATH=/shared/spack/bin:$PATH' >> ~/.bashrc
. ~/.bashrc
sudo yum install python3
```

* Tell spack we already have SLURM installed. Create `~/.spack/packages.yaml` and put this (take note of the slurm version using `srun --version`):
```
packages:
  slurm:
    paths:
      slurm@19.05.5: /opt/slurm/
    buildable: False
```

* Get software. **Note: I've kept version specifiers to match the Cannon configuration. A future version may be warranted.**:
```bash
spack install netcdf-c@4.7.3 r@3.6.3 proj@5.0.1 gdal@2.3.0 udunits@2.2.26 geos@3.6.2
```
Don't you just like it that packages can be installed so easily?

* Load the software by adding it to your environment in `~/.bashrc`:
```bash
# Discover environment
export PATH=$(spack location -i openmpi)/bin:$PATH
export PATH=$(spack location -i netcdf-c)/bin:$PATH
export PATH=$(spack location -i r)/bin:$PATH

export HOME_PROJ=$(spack location -i proj@5.0.1)
export HOME_GDAL=$(spack location -i gdal)
export HOME_UDUNITS=$(spack location -i udunits)
export HOME_GEOS=$(spack location -i geos)
export HOME_NETCDF=$(spack location -i netcdf-c)
export HOME_R=$(spack location -i r)

export PATH=$HOME_PROJ/bin:$HOME_GDAL/bin:$HOME_UDUNITS/bin:$HOME_GEOS/bin:$PATH
export LD_LIBRARY_PATH=$HOME_PROJ/lib:$HOME_GDAL/lib:$HOME_UDUNITS/lib:$HOME_GEOS/lib:$HOME_NETCDF/lib:$LD_LIBRARY_PATH
```

Taking note of specified package versions, if any.
Load the environment file: `. ~/.bashrc`.

* First create your R library directory. **Everything that needs to be shared by nodes needs to be on `/shared`!**
```bash
mkdir /shared/rlibs
export R_LIBS_USER=/shared/rlibs:$R_LIBS_USER
```

* Install some required developer dependencies
```bash
sudo yum install libcurl-devel
```

### Obtaining STILT
* Go to `/shared` and launch `R`. Make sure you are using R from spack and not a built-in copy using `which R` if you are unsure.
```R
install.packages('devtools')
install.packages("Rcpp")
install.packages("raster")
install.packages("dplyr")
install.packages("parallel")
install.packages("ncdf4")
install.packages("rslurm")
devtools::install_github('benfasoli/uataq')
require('uataq')
uataq::stilt_init('stilt_run')
```

### Setting up "Memory-Light" case: STILT Train Tutorial-02
