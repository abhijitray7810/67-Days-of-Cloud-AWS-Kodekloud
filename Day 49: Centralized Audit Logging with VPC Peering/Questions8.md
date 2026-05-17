The Nautilus DevOps team needs to build a secure and scalable log aggregation setup within their AWS environment. The goal is to gather log files from an internal EC2 instance running in a private VPC, transfer them securely to another EC2 instance in a public VPC, and then push those logs to a secure S3 bucket.

1) A VPC named xfusion-priv-vpc already exists with a private subnet named xfusion-priv-subnet, a route table named xfusion-priv-rt, and an EC2 instance named xfusion-priv-ec2 (using ubuntu image). This instance uses the SSH key pair xfusion-key.pem already available on the AWS client host at /root/.ssh/.

2) Your task is to:

Create a new VPC named xfusion-pub-vpc.
Create a subnet named xfusion-pub-subnet and a route table named xfusion-pub-rt under this public VPC.
Attach an internet gateway to xfusion-pub-vpc and configure the public route table to enable internet access.
Launch an EC2 instance named xfusion-pub-ec2 into the public subnet using the same key pair as the private instance.
Create an IAM role named xfusion-s3-role with PutObject permission to an S3 bucket and attach it to the public EC2 instance.
Create a new private S3 bucket named xfusion-s3-logs-7893.
Configure a VPC Peering named xfusion-vpc-peering between the private and public VPCs.
Modify both xfusion-priv-rt and xfusion-pub-rt to route each other's CIDR blocks through the peering connection.
On the private instance, configure a cron job to push the /var/log/boots.log file to the public instance (using scp or rsync).
On the public instance, configure a cron job to push that same file to the created S3 bucket.
The uploaded file must be stored in the S3 bucket under the path xfusion-priv-vpc/boot/boots.log.

Use below given AWS Credentials: (You can run the showcreds command on aws-client host to retrieve these credentials)

Console URL	https://274723590942.signin.aws.amazon.com/console?region=us-east-1
Username	kk_labs_user_575858
Password	2wObsU^@S3y6
Start Time	Sun May 17 12:56:47 UTC 2026
End Time	Sun May 17 13:56:47 UTC 2026

Notes:

Create the resources only in us-east-1 region.

To display or hide the terminal of the AWS client machine, you can use the expand toggle button as shown below:
toggle button




