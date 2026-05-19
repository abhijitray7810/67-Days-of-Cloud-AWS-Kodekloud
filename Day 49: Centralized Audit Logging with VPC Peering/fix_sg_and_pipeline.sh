#!/bin/bash
# ============================================================
#  Fix: Open port 22 on public SG from private VPC CIDR
#       then re-run the full pipeline test
# ============================================================
set -euo pipefail

REGION="us-east-1"
KEY_PATH="/root/.ssh/devops-key.pem"
S3_BUCKET="devops-s3-logs-9737"
S3_LOG_KEY="devops-priv-vpc/boot/boots.log"
PRIV_VPC_CIDR="10.10.0.0/16"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}  ✓  $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠  $1${NC}"; }
err()  { echo -e "${RED}  ✗  $1${NC}"; exit 1; }

SSH_PUB="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=15"
SCP_PUB="scp -i $KEY_PATH -o StrictHostKeyChecking=no"

# ── Recover IPs & SG ──────────────────────────────────────
PRIV_VPC_ID=$(aws ec2 describe-vpcs --region $REGION \
  --filters "Name=tag:Name,Values=devops-priv-vpc" \
  --query "Vpcs[0].VpcId" --output text)
PRIV_IP=$(aws ec2 describe-instances --region $REGION \
  --filters "Name=tag:Name,Values=devops-priv-ec2" \
            "Name=vpc-id,Values=$PRIV_VPC_ID" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
PUB_IP=$(aws ec2 describe-instances --region $REGION \
  --filters "Name=tag:Name,Values=devops-pub-ec2" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PUB_VPC_ID=$(aws ec2 describe-vpcs --region $REGION \
  --filters "Name=tag:Name,Values=devops-pub-vpc" \
  --query "Vpcs[0].VpcId" --output text)
PUB_SG_ID=$(aws ec2 describe-security-groups --region $REGION \
  --filters "Name=group-name,Values=devops-pub-sg" \
            "Name=vpc-id,Values=$PUB_VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text)

echo "Public  EC2 : $PUB_IP"
echo "Private EC2 : $PRIV_IP"
echo "Public SG   : $PUB_SG_ID"

# ── Fix: Add SSH rule from private VPC CIDR ───────────────
echo -e "\n[Fix] Adding SSH (port 22) inbound rule on $PUB_SG_ID from $PRIV_VPC_CIDR..."
aws ec2 authorize-security-group-ingress --region $REGION \
  --group-id $PUB_SG_ID \
  --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=${PRIV_VPC_CIDR},Description='SSH from private VPC'}]" \
  2>/dev/null && log "SSH rule added for $PRIV_VPC_CIDR" || warn "Rule may already exist"

# Show current ingress rules
echo -e "\n  Current ingress rules on $PUB_SG_ID:"
aws ec2 describe-security-groups --region $REGION \
  --group-ids $PUB_SG_ID \
  --query "SecurityGroups[0].IpPermissions[*].{Proto:IpProtocol,From:FromPort,To:ToPort,CIDR:IpRanges[0].CidrIp}" \
  --output table

# ── Test SSH from private EC2 → public EC2 ────────────────
echo -e "\n[Test] Verifying SSH from private EC2 → public EC2 (via jump)..."
$SSH_PUB ubuntu@$PUB_IP \
  "ssh -i /home/ubuntu/.ssh/devops-key.pem \
       -o StrictHostKeyChecking=no \
       -o ConnectTimeout=15 \
       ubuntu@${PRIV_IP} \
       \"ssh -i /home/ubuntu/.ssh/devops-key.pem \
             -o StrictHostKeyChecking=no \
             -o ConnectTimeout=15 \
             ubuntu@${PUB_IP} echo 'SSH priv→pub OK'\"" \
  && log "SSH from private EC2 to public EC2: WORKING" \
  || err "SSH from private EC2 to public EC2 still failing — check VPC peering routes"

# ── Run SCP: private → public ─────────────────────────────
echo -e "\n[Pipeline A] SCP boots.log: private EC2 → public EC2..."
$SSH_PUB ubuntu@$PUB_IP \
  "ssh -i /home/ubuntu/.ssh/devops-key.pem -o StrictHostKeyChecking=no ubuntu@${PRIV_IP} \
   'bash /home/ubuntu/push_log.sh && tail -2 /home/ubuntu/push_log.log'"
sleep 3

$SSH_PUB ubuntu@$PUB_IP "ls -lh /tmp/boots.log && echo '--- content ---' && cat /tmp/boots.log"
log "boots.log received on public EC2"

# ── Run S3 upload: public → S3 ────────────────────────────
echo -e "\n[Pipeline B] S3 upload: public EC2 → S3..."
$SSH_PUB ubuntu@$PUB_IP \
  "bash /home/ubuntu/push_to_s3.sh && tail -2 /home/ubuntu/s3_push.log"
sleep 5

# ── Verify in S3 ──────────────────────────────────────────
echo -e "\n[Verify] Checking S3..."
aws s3 ls "s3://$S3_BUCKET/$S3_LOG_KEY" --region $REGION \
  && log "FILE CONFIRMED: s3://$S3_BUCKET/$S3_LOG_KEY" \
  || err "File NOT found in S3!"

echo ""
echo "=========================================================="
echo "  Full pipeline verified!"
echo "  $PRIV_IP:/var/log/boots.log"
echo "    └─ scp ──► $PUB_IP:/tmp/boots.log"
echo "                 └─ s3://$S3_BUCKET/$S3_LOG_KEY"
echo "  Cron runs automatically every 5 min."
echo "=========================================================="
