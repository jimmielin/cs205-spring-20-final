# CS205 Spring 2020 Final Project: STILT Parallelization 
Quick intro or sth 

- [TOC - CS205 Spring 2020 Final Project: STILT Parallelization](#cs205-spring-2020-final-project--stilt-parallelization)
  * [Abstract](#abstract)
  * [Introduction](#introduction)
    + [Problem Description](#problem-description)
    + [Model Code](#model-code)
    + [The Needs for HPC and Big Data](#the-needs-for-hpc-and-big-data)
  * [Test Cases Experiments](#test-cases-experiments)
  * [Parallel Architecture Design](#parallel-architecture-design)
    + [Software Architecture](#software-architecture)
    + [Parallel Methods and Performance Analysis](#parallel-methods-and-performance-analysis)
      - [SLURM-based node parallelization](#slurm-based-node-parallelization)
      - [AWS Batch-based parallelization](#aws-batch-based-parallelization)
    + [Reproducibility Information](#reproducibility-information)
      - [SLURM-based on Harvard Cannon](#slurm-based-on-harvard-cannon)
      - [SLURM-based on AWS Cloud](#slurm-based-on-aws-cloud)
      - [AWS Batch](#aws-batch)
  * [Conclusion](#conclusion)
  * [References](#references)

## Abstract
...

## Introduction
### Problem Description
Stochastic Time-Inverted Lagrangian Transport Model or STILT model is an atmospheric model that simulates air parcel movements using ensembles of particles starting from a particular time and location.  Although the model can run both forward and backward in time from the given starting location, the backward runs are more commonly used. The knowledge of air particle trajectories depends on the specified receptors, which are the locations that the measurements were made.  From the information obtained via STILT, one can construct the influence of an atmospheric observation, which has proven to be extremely useful for understanding atmospheric datasets. As the numbers of particles and receptors increase, the information of specific atmospheric datasets increases as well as the computational cost. Thus, the main challenge of using STILT is to come up with optimal numbers of receptors, numbers of particles, and the time that needs to be running backward for.

### Model Code
The STILT model code used in this work is available at https://github.com/uataq/stilt. 

### The Needs for HPC and Big Data

### Solutions

In this project, we are applying a combination of two different solutions. The first solution is to use R Language based slurm batch commands to split the workload, simply following Fasoli et al. 2018's workflow. This solution is performed on both Harvard FAS Research Computer (i.e. Cannon) and AWS. The second solution is to develop a containerized, batch version of STILT designed for use on the AWS Cloud, with the ability of properly dealing with the input data, thus enables AWS Batch-based high-performance parallel executation of STILT. Detailed descriptions of both solutions and comparision with existing work is shown in section "Parallel Methods and Performance Analysis".

## Test Cases Experiments

We use two cases with different computational profiles to investigate STILT parallelization. A memory-lightweight case serves as proof-of-concept and is intended to be easily parallelizable. A second case is memory-intensive and ...

A STILT run requires the following datasets to run: (i) an emission dataset, (ii) a meteorological dataset, (iii) a receptor dataset, and (iv) an R script. 

For the memory-light case, we used what has been provided on the official STILT site.
https://uataq.github.io/stilt/tutorials/train.html

For the memory-intensive case, we used emission and receptor datasets based on a research project that studies greenhouse gas emissions in the New York City area. The meteorological product that we chose was the Global Forecast System. The meteorological reanalysis was from March 1st, 2019 https://www.ncdc.noaa.gov/data-access/model-data/model-datasets/global-forcast-system-gfs.

## Parallel Architecture Design

...

### Software Architecture

### Parallel Methods and Performance Analysis
#### SLURM-based node parallelization

STILT includes a SLURM workload manager-based parallelization capability which we benchmark, analyze and optimized on the two computational cases previously described. ...

#### AWS Batch-based parallelization

We develop a containerized, batch version of STILT designed for use on the AWS Cloud with AWS Batch. STILT includes a Docker container capability, however it only containerizes single-particle simulations on STILT, which incurs excessive overhead if a new container is deployed for every particle. The existing Docker container is further developed and a new version of the run script is built to allow for subsetting of input data and writing into a shared high-performance file system on AWS, powered by AWS FSx.

The new batch container is called STILT-batch and stored on AWS ECS (Elastic Container Service) repositories for private use, but can be readily publicly deployed in the future with permission from the STILT developers adopting our new code.

The previous STILT docker run script only accepted single particles, rendering it inappropriate for AWS Batch usage. The newly developed script accepts subsetting arguments that allow all batch processes to read from a single particle `RData` file, thus saving the user from troubles subsetting their data. The data subsetting is a simple even split in its current form and may be improved in the future to allow for dynamic load balancing. However, load balancing is likely not to be a significant issue in the current implementation, as once subset input data is fed into each batch worker, in-worker parallelization is achieved using dynamic scheduling of forked tasks.

We thus use the following architecture for our AWS Batch based parallelization approach:

** hplin: insert figure here **

This approach is a hybrid parallel approach. It is parallel at the node level by launching multiple batch workers, and parallel within nodes by launching multiple processes within each batch worker.

We benchmark this AWS Batch-based parallelization approach with the benchmark cases, by using different container sizes (number of cores per node) and different number of containers (number of nodes), and comparing to previous results for cost-efficiency and scalability.

...

### Reproducibility Information
#### SLURM-based on Harvard Cannon

#### SLURM-based on AWS Cloud
Please refer to the [STILT on AWS - ParallelCluster workflow document](https://github.com/jimmielin/cs205-spring-20-final/blob/master/docs/stilt_aws_slurm_workflow.md).

#### AWS Batch

Please refer to the [STILT on AWS - AWS Batch container creation](https://github.com/jimmielin/cs205-spring-20-final/blob/master/docs/stilt_aws_docker_workflow.md) for the creation steps for the container.

* **FSx High-Performance File System**: Created on `us-east-2` with storage capacity of `1.2 TiB` and `200 MB/s/TiB (up to 1.3 GB/s/TiB burst)` highest-performance option for a throughput capacity of `234 MB/s`. Mounted on `/fsx` through all AWS Batch instances. Pricing is calculated using **persistent, 200 MB/s/TiB baseline** cost of `$0.29 GB/month`. For this instance this works out to be `$356.352/month` or `$0.00330/second`.

Manual mount of this file system from within another EC2 instance is through the Lustre client:
```
sudo mount -t lustre -o noatime,flock fs-0a65a1969f67faf8b.fsx.us-east-2.amazonaws.com@tcp:/c5lb5bmv /fsx
```

Obtain the mount name (corresponding to the part after `tcp:/`) from `aws fsx describe-filesystems`. This has recently changed. Be careful.

Make sure that [the VPC security groups are correctly configured](https://docs.aws.amazon.com/fsx/latest/LustreGuide/limit-access-security-groups.html#fsx-vpc-security-groups) for both the FSx VPC and the VPC security group corresponding to the instances accessing the Lustre file system.

If all else fails, [here is troubleshooting instructions](https://docs.aws.amazon.com/fsx/latest/LustreGuide/troubleshooting.html).

Filesystem input setup:
```
$ ls -R /fsx
/fsx:        in  out
  /fsx/in:     HundredReceptors.RData  met
    /fsx/in/met:  20190301_gfs0p25
  /fsx/out:
```

* **Docker container stored on Amazon ECS (Elastic Container Storage).** Costs for AWS ECS not considered as it can be easily covered in the AWS ECR free-tier of 500 MB/month storage. Our container is sized twice the allowance but it does not need to be kept for long:

```
$ docker images --filter reference=stilt
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
stilt               latest              7e6c965f4677        4 hours ago         1.86GB
```



* **Launch Template**. Uses user data to mount the Lustre file system at `fsx`:
```
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/cloud-config; charset="us-ascii"

runcmd:
- file_system_id_01=fs-0a65a1969f67faf8b
- region=us-east-2
- fsx_directory=/c5lb5bmv
- amazon-linux-extras install -y lustre2.10
- mkdir -p ${fsx_directory}
- mount -t lustre ${file_system_id_01}.fsx.${region}.amazonaws.com@tcp:/c5lb5bmv ${fsx_directory}

--==MYBOUNDARY==--
```
In addition to a 8GB `gp2` mount at `/dev/xva` for base node-local storage.

* **Setting up AWS Batch**:
  + **Create Spot Fleet Role** for IAM [following these instructions](https://docs.aws.amazon.com/batch/latest/userguide/spot_fleet_IAM_role.html).
  + **Create Launch Template** as above.
  + **Create AWS Batch Compute Environment**: Created with `r5.2xlarge` (4C8T, 64GB Memory) instances only, accommodating 4 cores each. We use fixed instance types in our project but this could easily be adapted to scale to any combination of spot r5 instances. Use spot instances with the previously created spot fleet. Choose the `StiltBatchLT` launch template created above. Use the **Amazon Linux 2** [AMI](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html) (for `us-east-2` the AMI ID is `ami-0d9ef3d936a8fa1c6` as of time or writing)
  + **Create AWS Batch Job Queue** matching the compute environment above.
  + **Create Job Definition** using the `132714586118.dkr.ecr.us-east-2.amazonaws.com/stilt:latest` container stored as the "Container Image". Size is 4 vCPUs (cores) and `63500 MiB`. Make it slightly less than actual memory or it will be stuck in RUNNABLE. Set a volume with name "fsx" pointing to source path `/fsx` and a mount point in the container path `/fsx` with source volume "fsx".

* **Sample job**:
```
stilt_wd=/app recep_file_loc=/fsx/in/HundredReceptors.RData recep_idx_s=1 recep_idx_e=25 met_dir=/fsx/in/met met_file_format=%Y%m%d_gfs0p25 xmn=-74.8 xmx=-71 ymn=39.7 ymx=42.1 xres=0.01 yres=0.01 ncores=4
```

## Conclusion 

...


## References
Fasoli, Benjamin, et al. "Simulating atmospheric tracer concentrations for spatially distributed receptors: updates to the Stochastic Time-Inverted Lagrangian Transport model's R interface (STILT-R version 2)." Geoscientific Model Development 11.7 (2018). 
