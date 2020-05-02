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

