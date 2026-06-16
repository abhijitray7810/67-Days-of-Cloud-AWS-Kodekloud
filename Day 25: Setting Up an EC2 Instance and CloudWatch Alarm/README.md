# EC2 Instance & CloudWatch Alarm Setup (Nautilus DevOps)

This document describes the steps to launch an EC2 instance and configure a CloudWatch alarm to monitor CPU utilization using AWS CLI.

---
![image](https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/474f1e579e4980141fae62d6d7ea25f8ec1a3c49/Day%2025%3A%20Setting%20Up%20an%20EC2%20Instance%20and%20CloudWatch%20Alarm/Screenshot%202025-12-23%20213826.png)
## 📌 Requirements

- **Region:** us-east-1
- **EC2 Name:** datacenter-ec2 
- **Alarm Name:** datacenter-alarm
- **Metric:** CPUUtilization
- **Threshold:** ≥ 90%
- **Evaluation Period:** 1 × 5 minutes
- **SNS Topic:** datacenter-sns-topic (pre-created)

---
![image](https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/ccbae4385ce0c38d0097cfac93f6648e5a758391/Day%2025%3A%20Setting%20Up%20an%20EC2%20Instance%20and%20CloudWatch%20Alarm/Screenshot%202025-12-23%20213854.png)
## 🔐 AWS Credentials

Retrieve credentials on the `aws-client` host:

```bash
showcreds
````
![image](https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/6894d684c2d0b374dfa7a06d4fe5f43d566d1c1d/Day%2025%3A%20Setting%20Up%20an%20EC2%20Instance%20and%20CloudWatch%20Alarm/Screenshot%202025-12-23%20213904.png)
Configure AWS CLI:

```bash
aws configure
```

Provide:

* Access Key
* Secret Key
* Region: `us-east-1`
* Output format: `json`

````

---

## 🚀 Step 1: Launch EC2 Instance (Ubuntu)

### Get Latest Ubuntu AMI ID

```bash
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
  --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
  --output text
````

### Launch EC2 Instance

```bash
aws ec2 run-instances \
  --image-id <AMI_ID> \
  --instance-type t2.micro \
  --key-name <KEY_NAME> \
  --security-group-ids <SECURITY_GROUP_ID> \
  --subnet-id <SUBNET_ID> \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=datacenter-ec2}]'
```

---

## 📊 Step 2: Create CloudWatch Alarm

### Get SNS Topic ARN

```bash
aws sns list-topics \
  --query "Topics[?contains(TopicArn, 'datacenter-sns-topic')].TopicArn" \
  --output text
```

### Create CloudWatch Alarm

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name datacenter-alarm \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 90 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions <SNS_TOPIC_ARN> \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID>
```

---

## ✅ Verification

### Check EC2 Instance

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=datacenter-ec2"
```

### Check CloudWatch Alarm

```bash
aws cloudwatch describe-alarms \
  --alarm-names datacenter-alarm
```

---

## 📍 Notes

* All resources are created in **us-east-1**
* Alarm triggers when CPU usage ≥ 90% for **5 minutes**
* Notification is sent via **datacenter-sns-topic**

---

## 🏁 Conclusion

The EC2 instance and CloudWatch alarm have been successfully configured to monitor CPU utilization and notify the DevOps team when thresholds are breached.

---

**Author:** Abhijit Ray
**Role:** DevOps Engineer

```
