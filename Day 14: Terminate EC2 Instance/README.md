# EC2 Instance Cleanup Guide
![image] (https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/ae7de1a55f4670ed942aa9b679b1c35898591e9a/Day%2014%3A%20Terminate%20EC2%20Instance/Screenshot%202025-12-16%20001625.png)
## Overview
This document provides instructions for deleting the obsolete EC2 instance `xfusion-ec2` in the AWS `us-east-1` region.

## Prerequisites
- AWS CLI configured with proper credentials
- Access to the AWS Console or AWS CLI
- Permissions to terminate EC2 instances

## AWS Credentials
```
Console URL: https://305246191790.signin.aws.amazon.com/console?region=us-east-1
Username: kk_labs_user_613949
Password: 9h9xuy%O8W@!
Region: us-east-1
Session: Mon Dec 15 18:43:13 UTC 2025 - Mon Dec 15 19:43:13 UTC 2025
```

## Steps to Delete EC2 Instance

### Method 1: Using AWS CLI

1. **List the EC2 instance to get its Instance ID:**
   ```bash
   aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=xfusion-ec2" \
     --region us-east-1 \
     --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" \
     --output table
   ```

2. **Terminate the instance:**
   ```bash
   aws ec2 terminate-instances \
     --instance-ids <INSTANCE_ID> \
     --region us-east-1
   ```

3. **Verify the instance is terminated:**
   ```bash
   aws ec2 describe-instances \
     --instance-ids <INSTANCE_ID> \
     --region us-east-1 \
     --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
     --output table
   ```

### Method 2: Using AWS Console

1. Navigate to the EC2 Dashboard in the AWS Console
2. Ensure you're in the **us-east-1** region
3. Go to **Instances** in the left sidebar
4. Find the instance named **xfusion-ec2**
5. Select the instance
6. Click **Instance State** → **Terminate instance**
7. Confirm the termination
8. Wait for the instance state to change to **terminated**

## Verification Checklist

- [ ] Instance `xfusion-ec2` is located in `us-east-1` region
- [ ] Instance state shows as **terminated**
- [ ] No other resources are accidentally deleted

## Important Notes

- **Region**: All operations must be performed in `us-east-1` region
- **Instance State**: Ensure the instance reaches "terminated" state before completing the task
- **Termination Protection**: If enabled, it must be disabled before termination
- **Data Loss**: Terminating an instance will permanently delete any data stored on instance store volumes

## Troubleshooting

### Issue: Cannot terminate instance
**Solution**: Check if termination protection is enabled
```bash
aws ec2 describe-instance-attribute \
  --instance-id <INSTANCE_ID> \
  --attribute disableApiTermination \
  --region us-east-1
```

If enabled, disable it first:
```bash
aws ec2 modify-instance-attribute \
  --instance-id <INSTANCE_ID> \
  --no-disable-api-termination \
  --region us-east-1
```

### Issue: Instance stuck in shutting-down state
**Solution**: Wait a few minutes. The transition from shutting-down to terminated can take time.

## Completion Status

Once the instance state shows as **terminated**, the task is complete. The terminated instance will remain visible in the console for a short period before being removed automatically by AWS.

---

**Last Updated**: December 2025  
**Task**: Migration Cleanup - Remove obsolete resources
