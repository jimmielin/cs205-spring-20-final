# Creating Docker container for AWS Batch-based STILT
## Creating container

* Install Docker and enable the service. Make sure `docker info` works under your current user priviledges.

For details, check https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html, an excellent Amazon ECS tutorial.

* Use this modified CentOS 7-based `Dockerfile` for batch applications:
```
FROM centos:7
ENV R_LIBS_USER /app/rlibs

RUN yum -y install epel-release && yum -y install R

RUN R --version

RUN R -e "install.packages('devtools', repos='http://cran.us.r-project.org')"
RUN R -e "install.packages('Rcpp', repos='http://cran.us.r-project.org')"
RUN R -e "install.packages('raster', repos='http://cran.us.r-project.org')"
RUN R -e "install.packages('dplyr', repos='http://cran.us.r-project.org')"
RUN R -e "install.packages('parallel', repos='http://cran.us.r-project.org')"

RUN yum -y install netcdf netcdf-devel
RUN yum -y install libgfortran4

RUN R -e "install.packages('ncdf4', repos='http://cran.us.r-project.org')"
RUN R -e "install.packages('rslurm', repos='http://cran.us.r-project.org')"

WORKDIR /app

COPY . /app

ENV TZ UTC

VOLUME ["/app/in", "/app/out"]

ENTRYPOINT ["/app/r/stilt_cli_multi.r", \
                "stilt_wd=/app/", \
                "met_dir=/app/in/met"]
```

* Create the docker container: `docker built -t stilt .`. This will take a while.
* Verify the docker container operates correctly: This assumes you are using the ParallelCluster-based environment to build the container for testing.
```
docker run --rm --mount type=bind,source=/shared,destination=/app/in,readonly   --mount type=bind,source=/shared/out,destination=/app/out   stilt   stilt_wd=/app   recep_file_loc=/app/in/HundredReceptors.RData   recep_idx_s=5 recep_idx_e=10   met_dir=/app/in/met met_file_format=%Y%m%d_gfs0p25   xmn=-74.8 xmx=-71 ymn=39.7 ymx=42.1 xres=0.01 yres=0.01   ncores=1
```

## Upload container to Amazon ECR
* Upload the container for use in AWS Batch. Configure AWS using `aws configure` on the working machine.

* Create a docker repository on AWS ECR:
```
aws ecr create-repository --repository-name stilt --region us-east-2
```

* Verify it works: `aws ecr describe-repositories`
```
{
    "repositories": [
        {
            "repositoryUri": "132714586118.dkr.ecr.us-east-2.amazonaws.com/stilt",
            "imageScanningConfiguration": {
                "scanOnPush": false
            },
            "registryId": "132714586118",
            "imageTagMutability": "MUTABLE",
            "repositoryArn": "arn:aws:ecr:us-east-2:132714586118:repository/stilt",
            "repositoryName": "stilt",
            "createdAt": 1588730067.0
        }
    ]
}
```

* Upload:
```
docker tag stilt 132714586118.dkr.ecr.us-east-2.amazonaws.com/stilt
```