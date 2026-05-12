Perfect — IAM role attachment is working correctly.

Now continue with VPC peering.

# Create VPC Peering

```bash id="2vxpb3"
PEER=$(aws ec2 create-vpc-peering-connection \
  --vpc-id $PRIV_VPC \
  --peer-vpc-id $PUB_VPC \
  --query "VpcPeeringConnection.VpcPeeringConnectionId" \
  --output text)

echo $PEER
```

Accept peering:

```bash id="t6ex4t"
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id $PEER
```

Get public VPC CIDR:

```bash id="jlwm8v"
PUB_CIDR=$(aws ec2 describe-vpcs \
  --vpc-ids $PUB_VPC \
  --query "Vpcs[0].CidrBlock" \
  --output text)

echo $PUB_CIDR
```

Add routes.

Private route table → public VPC:

```bash id="mbp1vw"
aws ec2 create-route \
  --route-table-id $PRIV_RT \
  --destination-cidr-block $PUB_CIDR \
  --vpc-peering-connection-id $PEER
```

Public route table → private VPC:

```bash id="iy5k2p"
aws ec2 create-route \
  --route-table-id $PUB_RT \
  --destination-cidr-block $PRIV_CIDR \
  --vpc-peering-connection-id $PEER
```

Then get the public instance IP:

```bash id="h79nq4"
PUB_IP=$(aws ec2 describe-instances \
  --instance-ids $PUB_EC2 \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo $PUB_IP
```

After that, we’ll configure the cron jobs on both EC2 instances.
