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
The STILT model code used in this work is available at ... 

### The Needs for HPC and Big Data

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

#### AWS Batch

...

## Conclusion 

...


## References
