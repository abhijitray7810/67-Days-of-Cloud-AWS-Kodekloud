# EC2 Instance with Elastic IP Setup - README 
![image](https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/d2048f68afeca9230209c49549acfc60fd2393b2/Date%2021%3A%20Setting%20Up%20an%20EC2%20Instance%20with%20an%20Elastic%20IP%20for%20Application%20Hosting/Screenshot%202025-12-17%20194123.png)
## Overview 
This guide provides steps to create an EC2 instance named `nautilus-ec2` with an associated Elastic IP named `nautilus-eip` for the Nautilus DevOps Team.

## Prerequisites
- AWS Account access with provided credentials
- AWS CLI configured or AWS Console access
- Region: `us-east-1`
![image](https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/687f7cf0bb8f3671523faee7ae207bc95262c309/Date%2021%3A%20Setting%20Up%20an%20EC2%20Instance%20with%20an%20Elastic%20IP%20for%20Application%20Hosting/Screenshot%202025-12-17%20194313.png)
## Steps

### 1. Login to AWS Console
- Navigate to: https://047198242333.signin.aws.amazon.com/console?region=us-east-1
- Username: `kk_labs_user_196948`
- Password: `DGB^p^9@ocKtStart`
- Ensure region is set to **us-east-1**
![image](https://github.com/abhijitray7810/100-Days-of-Cloud-AWS-Kodekloud/blob/95d700a4014192e0882ec74691723d0d41a13410/Date%2021%3A%20Setting%20Up%20an%20EC2%20Instance%20with%20an%20Elastic%20IP%20for%20Application%20Hosting/Screenshot%202025-12-17%20194256.png)
### 2. Create EC2 Instance
- Go to EC2 Dashboard
- Click "Launch Instance"
- Set Name: `nautilus-ec2`
- Select AMI: Ubuntu (or any Linux AMI)
- Instance Type: `t2.micro`
- Configure other settings as needed (VPC, Security Group, Key Pair)
- Launch the instance

### 3. Allocate Elastic IP
- In EC2 Dashboard, navigate to "Elastic IPs" under "Network & Security"
- Click "Allocate Elastic IP address"
- Select "Amazon's pool of IPv4 addresses"
- Add tag: Name = `nautilus-eip`
- Click "Allocate"

### 4. Associate Elastic IP with EC2 Instance
- Select the newly created Elastic IP
- Click "Actions" → "Associate Elastic IP address"
- Select Instance: `nautilus-ec2`
- Click "Associate"

### 5. Verify Setup
- Check EC2 instance has the Elastic IP assigned
- Confirm the Elastic IP is tagged as `nautilus-eip`
- Verify the instance is in running state

## Important Notes
- All resources must be created in **us-east-1** region only
- Instance type must be **t2.micro**
- Session expires at: Wed Dec 17 14:58:17 UTC 2025

## Result
The `nautilus-ec2` instance will have a stable public IP address via the `nautilus-eip` Elastic IP, providing consistent access for the Development Team's application.
