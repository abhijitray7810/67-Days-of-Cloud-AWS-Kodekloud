The issue is that the private EC2 does not have the SSH private key needed to SCP into the public EC2.

You are currently inside the private EC2.
Copy the key from the public EC2 to the private EC2 first.

From the private EC2, run:

```bash id="8b9w5p"
scp -i ~/.ssh/datacenter-key.pem ~/.ssh/datacenter-key.pem ubuntu@10.10.1.161:/home/ubuntu/.ssh/
```

That command may not work because you are already inside private EC2. So instead do this:

## Step 1 — Exit back to Public EC2

```bash id="fdjlwm"
exit
```

You should now be on:

```text id="o8rsl7"
ubuntu@ip-10-20-1-118
```

## Step 2 — Copy key into Private EC2

Run:

```bash id="3j3m4w"
scp -i ~/.ssh/datacenter-key.pem ~/.ssh/datacenter-key.pem ubuntu@10.10.1.161:/home/ubuntu/.ssh/
```

Type `yes` if prompted.

## Step 3 — SSH back into Private EC2

```bash id="2c4hjr"
ssh -i ~/.ssh/datacenter-key.pem ubuntu@10.10.1.161
```

## Step 4 — Fix permissions

```bash id="t9f22u"
chmod 400 ~/.ssh/datacenter-key.pem
```

## Step 5 — Update script

```bash id="qjlwm7"
cat > /home/ubuntu/send-log.sh <<'EOF'
#!/bin/bash
scp -i /home/ubuntu/.ssh/datacenter-key.pem -o StrictHostKeyChecking=no /var/log/boots.log ubuntu@10.20.1.118:/tmp/boots.log
EOF
```

Make executable:

```bash id="o7x6pn"
chmod +x /home/ubuntu/send-log.sh
```

## Step 6 — Test again

```bash id="3xuknr"
bash /home/ubuntu/send-log.sh
```

If no error appears, cron will work correctly.

Finally, from `aws-client`, verify:

```bash id="7n3vdp"
aws s3 ls s3://datacenter-s3-logs-20934/datacenter-priv-vpc/boot/
```

You should see:

```text id="mjlwm0"
boots.log
```
