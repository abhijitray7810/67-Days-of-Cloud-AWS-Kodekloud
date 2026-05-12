Run this instead:

```bash id="r9z4dg"
sudo snap install aws-cli --classic
```

Then verify:

```bash id="7vw4rn"
aws --version
```

After AWS CLI is installed, continue:

```bash id="a95f62"
sudo tee /usr/local/bin/upload-to-s3.sh > /dev/null <<'EOF'
#!/bin/bash
aws s3 cp /tmp/boots.log s3://datacenter-s3-logs-20934/datacenter-priv-vpc/boot/boots.log
EOF
```

Make it executable:

```bash id="vj51yb"
sudo chmod +x /usr/local/bin/upload-to-s3.sh
```

Create a test file:

```bash id="d9ov11"
sudo touch /tmp/boots.log
```

Run upload manually:

```bash id="xksl1s"
sudo /usr/local/bin/upload-to-s3.sh
```

If no error appears, add cron:

```bash id="5f6s3f"
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/upload-to-s3.sh") | crontab -
```

Verify:

```bash id="n3j3fy"
crontab -l
```

Then exit:

```bash id="2q4r92"
exit
```

After that we’ll configure the private EC2 instance.
