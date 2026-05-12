Excellent — the public EC2 → S3 upload is working.

Now configure the private EC2 instance.

First exit from the public instance:

```bash id="vwjv5h"
exit
```

Back on `aws-client`, get the private instance private IP:

```bash id="vzjlwm"
aws ec2 describe-instances \
  --instance-ids $PRIV_EC2 \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text
```

Copy the IP.

Now SSH into the private instance:

Example:

```bash id="4ub9qr"
ssh -i /root/.ssh/datacenter-key.pem ubuntu@10.x.x.x
```

Inside the private instance, create the transfer script.

Replace `3.83.189.175` with your public EC2 IP if different:

```bash id="v4d4v8"
cat > /home/ubuntu/send-log.sh <<'EOF'
#!/bin/bash
scp -o StrictHostKeyChecking=no /var/log/boots.log ubuntu@3.83.189.175:/tmp/boots.log
EOF
```

Make executable:

```bash id="5nl1z9"
chmod +x /home/ubuntu/send-log.sh
```

Test manually:

```bash id="ksh1j0"
bash /home/ubuntu/send-log.sh
```

If it asks about host authenticity:

```text id="c4vj8i"
yes
```

If successful, add cron:

```bash id="9avmsi"
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/send-log.sh") | crontab -
```

Verify:

```bash id="hl0mtt"
crontab -l
```

Finally verify from `aws-client`:

```bash id="2t9i3m"
aws s3 ls s3://datacenter-s3-logs-20934/datacenter-priv-vpc/boot/
```

You should see:

```text id="4kigzw"
boots.log
```
