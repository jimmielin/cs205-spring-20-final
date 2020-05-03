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

* **Configure the `pcluster` stack before first run.** Read questions carefully, suggested answers are below. We are using `t2.micro` as master and `c5.4xlarge` as testing compute setups here, but you may want to check out the work to determine which set is best for you.

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
Master instance type [t2.micro]:
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
