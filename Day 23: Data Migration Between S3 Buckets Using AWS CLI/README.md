# S3 Data Migration Using AWS CLI

## 📌 Project Overview
This project demonstrates how to migrate data from an existing Amazon S3 bucket to a newly created S3 bucket using the **AWS CLI**, ensuring complete data consistency and integrity. The task was performed as part of a data migration requirement for the **Nautilus DevOps Team**.

---

## 🎯 Objectives
- Create a new **private S3 bucket**
- Migrate all data from the existing bucket to the new bucket
- Ensure both buckets contain identical data
- Perform all operations using AWS CLI 
- Use the **us-east-1** AWS region

--- 

## 🛠️ Prerequisites 
Before starting, ensure the following: 

- AWS CLI installed and configured
- IAM user/role with permissions:
  - `s3:CreateBucket`
  - `s3:ListBucket`
  - `s3:GetObject`
  - `s3:PutObject`
- AWS credentials configured using:
  ```bash
  aws configure
````

---

## 🌍 AWS Region

All resources are created in:

```
us-east-1
```

---

## 📂 Bucket Details

| Type               | Bucket Name             |
| ------------------ | ----------------------- |
| Source Bucket      | `datacenter-s3-19640`   |
| Destination Bucket | `datacenter-sync-27127` |

---

## 🚀 Implementation Steps

### 1️⃣ Set AWS Region

```bash
aws configure set region us-east-1
```

---

### 2️⃣ Create New Private S3 Bucket

```bash
aws s3api create-bucket \
  --bucket datacenter-sync-27127 \
  --region us-east-1
```

> By default, Amazon S3 buckets are private.

---

### 3️⃣ Migrate Data Using AWS CLI Sync

```bash
aws s3 sync s3://datacenter-s3-19640 s3://datacenter-sync-27127
```

✅ This command:

* Copies all objects recursively
* Maintains directory structure
* Avoids re-copying unchanged files

---

## 🔍 Data Consistency Verification

### ✔️ Compare Object Count

```bash
aws s3 ls s3://datacenter-s3-19640 --recursive | wc -l
aws s3 ls s3://datacenter-sync-27127 --recursive | wc -l
```

---

### ✔️ Dry Run Sync Check

```bash
aws s3 sync s3://datacenter-s3-19640 s3://datacenter-sync-27127 --dryrun
```

> No output indicates both buckets are fully synchronized.

---

### ✔️ Optional Spot Check

```bash
aws s3 ls s3://datacenter-s3-19640 --recursive | head
aws s3 ls s3://datacenter-sync-27127 --recursive | head
```

---

## ✅ Outcome

* New S3 bucket successfully created
* All data migrated without loss or corruption
* Source and destination buckets are fully synchronized
* Data integrity verified using AWS CLI tools

---

## 🏁 Conclusion

This project showcases a reliable and efficient approach to S3 data migration using AWS CLI while maintaining data accuracy and consistency. The `aws s3 sync` command ensures a production-ready migration strategy suitable for real-world DevOps workflows.

---

## 👤 Author

**Nautilus DevOps Team**
*AWS | Cloud | DevOps*

---

```

If you want, I can also:
- Customize it for **GitHub**
- Add **architecture diagram**
- Make it **interview-ready**
- Convert it into **DevOps daily challenge format**

Just tell me 👍
```
