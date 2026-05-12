Your lab IAM user does not have permission for inline IAM policies (`iam:PutRolePolicy`).
Use an AWS managed policy instead.

Run these commands instead:

```bash id="4qvx7k"
aws iam attach-role-policy \
  --role-name datacenter-s3-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

Then continue:

```bash id="kmqejg"
aws iam create-instance-profile \
  --instance-profile-name datacenter-s3-profile
```

```bash id="k9m2vl"
aws iam add-role-to-instance-profile \
  --instance-profile-name datacenter-s3-profile \
  --role-name datacenter-s3-role
```

Wait about 20 seconds, then attach the instance profile:

```bash id="ctsnx0"
aws ec2 associate-iam-instance-profile \
  --instance-id $PUB_EC2 \
  --iam-instance-profile Name=datacenter-s3-profile
```

Then continue with VPC peering and cron-job configuration.
