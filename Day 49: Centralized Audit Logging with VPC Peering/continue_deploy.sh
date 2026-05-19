#!/bin/bash
# ============================================================
#  Nautilus DevOps - Continuation Script (Fixed)
#  Run on the KodeKloud aws-client host as root
# ============================================================
set -euo pipefail

REGION="us-east-1"
PUB_VPC_CIDR="10.1.0.0/16"
KEY_NAME="devops-key"
KEY_PATH="/root/.ssh/devops-key.pem"
S3_BUCKET="devops-s3-logs-9737"
IAM_ROLE="devops-s3-role"
S3_LOG_KEY="devops-priv-vpc/boot/boots.log"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}  ✓  $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠  $1${NC}"; }
err()  { echo -e "${RED}  ✗  $1${NC}"; exit 1; }

echo "=========================================================="
echo "  Nautilus DevOps - Continuation (Step 7 onwards)"
echo "=========================================================="

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ── Recover IDs from already-created resources ─────────────
echo -e "\n[Recover] Reading existing resource IDs..."

PRIV_VPC_ID=$(aws ec2 describe-vpcs --region $REGION \
  --filters "Name=tag:Name,Values=devops-priv-vpc" \
  --query "Vpcs[0].VpcId" --output text)
PRIV_VPC_CIDR=$(aws ec2 describe-vpcs --region $REGION \
  --vpc-ids $PRIV_VPC_ID --query "Vpcs[0].CidrBlock" --output text)
PRIV_RT_ID=$(aws ec2 describe-route-tables --region $REGION \
  --filters "Name=tag:Name,Values=devops-priv-rt" "Name=vpc-id,Values=$PRIV_VPC_ID" \
  --query "RouteTables[0].RouteTableId" --output text)
PRIV_EC2_ID=$(aws ec2 describe-instances --region $REGION \
  --filters "Name=tag:Name,Values=devops-priv-ec2" "Name=vpc-id,Values=$PRIV_VPC_ID" \
            "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)
PRIV_IP=$(aws ec2 describe-instances --region $REGION \
  --instance-ids $PRIV_EC2_ID \
  --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

PUB_VPC_ID=$(aws ec2 describe-vpcs --region $REGION \
  --filters "Name=tag:Name,Values=devops-pub-vpc" \
  --query "Vpcs[0].VpcId" --output text)
PUB_SUBNET_ID=$(aws ec2 describe-subnets --region $REGION \
  --filters "Name=tag:Name,Values=devops-pub-subnet" "Name=vpc-id,Values=$PUB_VPC_ID" \
  --query "Subnets[0].SubnetId" --output text)
PUB_RT_ID=$(aws ec2 describe-route-tables --region $REGION \
  --filters "Name=tag:Name,Values=devops-pub-rt" "Name=vpc-id,Values=$PUB_VPC_ID" \
  --query "RouteTables[0].RouteTableId" --output text)
SG_ID=$(aws ec2 describe-security-groups --region $REGION \
  --filters "Name=group-name,Values=devops-pub-sg" "Name=vpc-id,Values=$PUB_VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text)

log "Private VPC : $PRIV_VPC_ID ($PRIV_VPC_CIDR) | RT: $PRIV_RT_ID"
log "Public  VPC : $PUB_VPC_ID | Subnet: $PUB_SUBNET_ID | RT: $PUB_RT_ID | SG: $SG_ID"
log "Private EC2 : $PRIV_EC2_ID @ $PRIV_IP"

# ── Step 7: Attach S3 policy to IAM role ──────────────────
echo -e "\n[7] Attaching S3 policy to IAM role ($IAM_ROLE)..."

aws iam attach-role-policy \
  --role-name $IAM_ROLE \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
  2>/dev/null && log "Attached AmazonS3FullAccess" || warn "Policy may already be attached"

# Create scoped custom policy
CUSTOM_POLICY_ARN=$(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='devops-s3-put-policy'].Arn" \
  --output text 2>/dev/null)

if [[ -z "$CUSTOM_POLICY_ARN" || "$CUSTOM_POLICY_ARN" == "None" ]]; then
  CUSTOM_POLICY_ARN=$(aws iam create-policy \
    --policy-name devops-s3-put-policy \
    --policy-document "{
      \"Version\": \"2012-10-17\",
      \"Statement\": [{
        \"Effect\": \"Allow\",
        \"Action\": [\"s3:PutObject\",\"s3:GetObject\",\"s3:ListBucket\"],
        \"Resource\": [
          \"arn:aws:s3:::${S3_BUCKET}\",
          \"arn:aws:s3:::${S3_BUCKET}/*\"
        ]
      }]
    }" --query "Policy.Arn" --output text)
  log "Created custom policy: $CUSTOM_POLICY_ARN"
else
  log "Custom policy exists: $CUSTOM_POLICY_ARN"
fi

aws iam attach-role-policy \
  --role-name $IAM_ROLE \
  --policy-arn "$CUSTOM_POLICY_ARN" \
  2>/dev/null && log "Attached custom S3 PutObject policy" || warn "Already attached"

aws iam create-instance-profile \
  --instance-profile-name $IAM_ROLE \
  2>/dev/null && log "Created instance profile" || warn "Instance profile already exists"

aws iam add-role-to-instance-profile \
  --instance-profile-name $IAM_ROLE \
  --role-name $IAM_ROLE \
  2>/dev/null && log "Added role to instance profile" || warn "Role already in profile"

echo "  Waiting 15s for IAM propagation..."
sleep 15

# ── Step 8: Launch public EC2 ──────────────────────────────
echo -e "\n[8] Launching public EC2 (devops-pub-ec2)..."
PUB_EC2_ID=$(aws ec2 describe-instances --region $REGION \
  --filters "Name=tag:Name,Values=devops-pub-ec2" \
            "Name=instance-state-name,Values=running,pending,stopped" \
  --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null)

if [[ -z "$PUB_EC2_ID" || "$PUB_EC2_ID" == "None" ]]; then
  AMI_ID=$(aws ec2 describe-images --region $REGION \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
              "Name=state,Values=available" "Name=architecture,Values=x86_64" \
    --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text)
  log "Using AMI: $AMI_ID"

  PUB_EC2_ID=$(aws ec2 run-instances --region $REGION \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --subnet-id $PUB_SUBNET_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --iam-instance-profile Name=$IAM_ROLE \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=devops-pub-ec2}]" \
    --query "Instances[0].InstanceId" --output text)
  log "Launched: $PUB_EC2_ID — waiting for running state..."
  aws ec2 wait instance-running --region $REGION --instance-ids $PUB_EC2_ID
  log "Instance is running"
else
  warn "Already exists: $PUB_EC2_ID"
  PROFILE=$(aws ec2 describe-instances --region $REGION \
    --instance-ids $PUB_EC2_ID \
    --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text 2>/dev/null)
  if [[ -z "$PROFILE" || "$PROFILE" == "None" ]]; then
    aws ec2 associate-iam-instance-profile --region $REGION \
      --instance-id $PUB_EC2_ID \
      --iam-instance-profile Name=$IAM_ROLE \
      2>/dev/null && log "IAM profile attached" || warn "Could not attach profile"
  else
    warn "IAM profile already attached"
  fi
fi

PUB_IP=$(aws ec2 describe-instances --region $REGION \
  --instance-ids $PUB_EC2_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
log "Public EC2: $PUB_EC2_ID @ $PUB_IP"

# ── Step 9: S3 Bucket ──────────────────────────────────────
echo -e "\n[9] Creating private S3 bucket ($S3_BUCKET)..."
aws s3api create-bucket --bucket $S3_BUCKET --region $REGION \
  2>/dev/null && log "Created bucket" || warn "Bucket already exists"

aws s3api put-public-access-block --bucket $S3_BUCKET \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
log "Blocked all public access"

aws s3api put-bucket-versioning --bucket $S3_BUCKET \
  --versioning-configuration Status=Enabled
log "Enabled versioning"

# ── Step 10: VPC Peering ───────────────────────────────────
echo -e "\n[10] Creating VPC Peering (devops-vpc-peering)..."
PCX_ID=$(aws ec2 describe-vpc-peering-connections --region $REGION \
  --filters "Name=tag:Name,Values=devops-vpc-peering" \
            "Name=status-code,Values=active,pending-acceptance" \
  --query "VpcPeeringConnections[0].VpcPeeringConnectionId" --output text 2>/dev/null)

if [[ -z "$PCX_ID" || "$PCX_ID" == "None" ]]; then
  PCX_ID=$(aws ec2 create-vpc-peering-connection --region $REGION \
    --vpc-id $PUB_VPC_ID --peer-vpc-id $PRIV_VPC_ID \
    --query "VpcPeeringConnection.VpcPeeringConnectionId" --output text)
  aws ec2 create-tags --region $REGION \
    --resources $PCX_ID --tags Key=Name,Value=devops-vpc-peering
  sleep 3
  aws ec2 accept-vpc-peering-connection --region $REGION \
    --vpc-peering-connection-id $PCX_ID
  log "Created & accepted: $PCX_ID"
else
  warn "Already exists: $PCX_ID"
fi

# ── Step 11: Update route tables ──────────────────────────
echo -e "\n[11] Adding peering routes to route tables..."

aws ec2 create-route --region $REGION \
  --route-table-id $PRIV_RT_ID \
  --destination-cidr-block $PUB_VPC_CIDR \
  --vpc-peering-connection-id $PCX_ID \
  2>/dev/null && log "priv-rt → $PUB_VPC_CIDR via $PCX_ID" || warn "Route already exists in priv-rt"

aws ec2 create-route --region $REGION \
  --route-table-id $PUB_RT_ID \
  --destination-cidr-block $PRIV_VPC_CIDR \
  --vpc-peering-connection-id $PCX_ID \
  2>/dev/null && log "pub-rt → $PRIV_VPC_CIDR via $PCX_ID" || warn "Route already exists in pub-rt"

# ── Step 12: Update private SG ────────────────────────────
echo -e "\n[12] Updating private VPC security groups to allow pub VPC traffic..."
PRIV_SGS=$(aws ec2 describe-security-groups --region $REGION \
  --filters "Name=vpc-id,Values=$PRIV_VPC_ID" \
  --query "SecurityGroups[*].GroupId" --output text)

for SG in $PRIV_SGS; do
  aws ec2 authorize-security-group-ingress --region $REGION \
    --group-id $SG \
    --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=$PUB_VPC_CIDR,Description='From public VPC'}]" \
    2>/dev/null && log "Updated SG $SG" || warn "Rule already exists in SG $SG"
done

# ── Step 13: Build remote scripts locally, then deploy ────
echo -e "\n[13] Building and deploying cron job scripts..."

# --- Script that runs on PUBLIC EC2 ---
cat > /tmp/pub_ec2_setup.sh << PUBEOF
#!/bin/bash
set -e

# Install AWS CLI v2 if missing
if ! command -v aws &>/dev/null; then
  echo "Installing AWS CLI v2..."
  sudo apt-get update -y -q
  sudo apt-get install -y -q unzip curl
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp/awscli_install
  sudo /tmp/awscli_install/aws/install
fi
echo "AWS CLI: \$(aws --version)"

# Write push-to-S3 script (vars already substituted by envsubst)
cat > /home/ubuntu/push_to_s3.sh << 'INNEREOF'
#!/bin/bash
LOCAL="/tmp/boots.log"
BUCKET="__S3_BUCKET__"
S3_KEY="__S3_LOG_KEY__"
REGION="__REGION__"
LOGFILE="/home/ubuntu/s3_push.log"
if [ -f "\$LOCAL" ]; then
  aws s3 cp "\$LOCAL" "s3://\$BUCKET/\$S3_KEY" --region \$REGION \
    && echo "\$(date): SUCCESS - uploaded to s3://\$BUCKET/\$S3_KEY" >> "\$LOGFILE" \
    || echo "\$(date): FAILED - aws s3 cp error" >> "\$LOGFILE"
else
  echo "\$(date): SKIP - \$LOCAL not found" >> "\$LOGFILE"
fi
INNEREOF

# Substitute placeholders
sed -i "s|__S3_BUCKET__|${S3_BUCKET}|g" /home/ubuntu/push_to_s3.sh
sed -i "s|__S3_LOG_KEY__|${S3_LOG_KEY}|g" /home/ubuntu/push_to_s3.sh
sed -i "s|__REGION__|${REGION}|g"         /home/ubuntu/push_to_s3.sh
chmod +x /home/ubuntu/push_to_s3.sh

# Install cron job
( crontab -l 2>/dev/null | grep -v push_to_s3; \
  echo "*/5 * * * * /home/ubuntu/push_to_s3.sh" ) | crontab -

echo "=== Public EC2 crontab ==="
crontab -l
PUBEOF

# --- Script that runs on PRIVATE EC2 ---
cat > /tmp/priv_ec2_setup.sh << PRIVEOF
#!/bin/bash
set -e

# Create /var/log/boots.log if missing and seed it
sudo touch /var/log/boots.log
sudo chmod 644 /var/log/boots.log
if [ ! -s /var/log/boots.log ]; then
  echo "\$(date): System boot log - initialized by devops setup" | sudo tee /var/log/boots.log
  [ -f /var/log/boot.log ] && sudo cat /var/log/boot.log | sudo tee -a /var/log/boots.log || true
fi

# Write SCP push script (placeholders substituted below)
cat > /home/ubuntu/push_log.sh << 'INNEREOF'
#!/bin/bash
SRC="/var/log/boots.log"
DEST_USER="ubuntu"
DEST_HOST="__PUB_IP__"
KEY="/home/ubuntu/.ssh/devops-key.pem"
LOGFILE="/home/ubuntu/push_log.log"
scp -i "\$KEY" -o StrictHostKeyChecking=no "\$SRC" "\$DEST_USER@\$DEST_HOST:/tmp/boots.log" \
  && echo "\$(date): SUCCESS - pushed boots.log to \$DEST_HOST" >> "\$LOGFILE" \
  || echo "\$(date): FAILED - scp error" >> "\$LOGFILE"
INNEREOF

sed -i "s|__PUB_IP__|${PUB_IP}|g" /home/ubuntu/push_log.sh
chmod +x /home/ubuntu/push_log.sh

# Install cron job
( crontab -l 2>/dev/null | grep -v push_log; \
  echo "*/5 * * * * /home/ubuntu/push_log.sh" ) | crontab -

echo "=== Private EC2 crontab ==="
crontab -l
PRIVEOF

# Wait for SSH availability on public EC2
echo "  Waiting for SSH on public EC2 ($PUB_IP)..."
for i in {1..12}; do
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
    ubuntu@$PUB_IP "echo connected" 2>/dev/null && break
  echo "  Attempt $i/12, retrying in 10s..."
  sleep 10
done

# [A] Copy SSH key to public EC2
echo "  [A] Copying devops-key.pem to public EC2..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
  "$KEY_PATH" ubuntu@$PUB_IP:/home/ubuntu/.ssh/devops-key.pem
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUB_IP \
  "chmod 600 /home/ubuntu/.ssh/devops-key.pem"
log "Key copied to public EC2"

# [B] Deploy and run public EC2 setup
echo "  [B] Deploying setup script to public EC2..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
  /tmp/pub_ec2_setup.sh ubuntu@$PUB_IP:/tmp/pub_ec2_setup.sh
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUB_IP \
  "bash /tmp/pub_ec2_setup.sh"
log "Public EC2 cron configured"

# [C] Deploy private EC2 setup via jump through public EC2
echo "  [C] Deploying setup script to private EC2 via jump host..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no \
  /tmp/priv_ec2_setup.sh ubuntu@$PUB_IP:/tmp/priv_ec2_setup.sh

ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUB_IP \
  "scp -i /home/ubuntu/.ssh/devops-key.pem -o StrictHostKeyChecking=no \
     /tmp/priv_ec2_setup.sh ubuntu@${PRIV_IP}:/tmp/priv_ec2_setup.sh && \
   ssh -i /home/ubuntu/.ssh/devops-key.pem -o StrictHostKeyChecking=no \
     ubuntu@${PRIV_IP} 'bash /tmp/priv_ec2_setup.sh'"
log "Private EC2 cron configured"

# ── Step 14: Immediate end-to-end test ───────────────────
echo -e "\n[14] Running immediate end-to-end pipeline test..."

echo "  Triggering SCP: private EC2 → public EC2..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUB_IP \
  "ssh -i /home/ubuntu/.ssh/devops-key.pem -o StrictHostKeyChecking=no \
   ubuntu@${PRIV_IP} 'bash /home/ubuntu/push_log.sh'" \
  && log "SCP push (priv → pub): SUCCESS" \
  || warn "SCP push had issues — check /home/ubuntu/push_log.log on private EC2"

sleep 5

echo "  Triggering S3 upload: public EC2 → S3..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$PUB_IP \
  "bash /home/ubuntu/push_to_s3.sh" \
  && log "S3 upload (pub → S3): SUCCESS" \
  || warn "S3 upload had issues — check /home/ubuntu/s3_push.log on public EC2"

sleep 5

echo -e "\n[Verify] Confirming file in S3..."
aws s3 ls "s3://$S3_BUCKET/$S3_LOG_KEY" --region $REGION \
  && log "FILE CONFIRMED: s3://$S3_BUCKET/$S3_LOG_KEY" \
  || warn "File not yet in S3 — check logs on both instances"

# ── Final Summary ──────────────────────────────────────────
echo ""
echo "=========================================================="
echo "  DEPLOYMENT COMPLETE"
echo "=========================================================="
printf "  %-16s %s\n" "Private VPC:"  "$PRIV_VPC_ID ($PRIV_VPC_CIDR)"
printf "  %-16s %s\n" "Public VPC:"   "$PUB_VPC_ID ($PUB_VPC_CIDR)"
printf "  %-16s %s\n" "VPC Peering:"  "$PCX_ID"
printf "  %-16s %s\n" "Public RT:"    "$PUB_RT_ID (0.0.0.0/0 → IGW)"
printf "  %-16s %s\n" "Private RT:"   "$PRIV_RT_ID ($PUB_VPC_CIDR → peering)"
printf "  %-16s %s\n" "Public EC2:"   "$PUB_EC2_ID @ $PUB_IP"
printf "  %-16s %s\n" "Private EC2:"  "$PRIV_EC2_ID @ $PRIV_IP"
printf "  %-16s %s\n" "IAM Role:"     "$IAM_ROLE"
printf "  %-16s %s\n" "S3 Bucket:"    "s3://$S3_BUCKET (private + versioned)"
echo ""
echo "  Pipeline (cron every 5 min):"
echo "  $PRIV_IP:/var/log/boots.log"
echo "    └─ scp ──► $PUB_IP:/tmp/boots.log"
echo "                 └─ aws s3 cp ──► s3://$S3_BUCKET/$S3_LOG_KEY"
echo "=========================================================="
