Your `$PRIV_VPC` or `$PUB_VPC` variables are not currently set in the shell session.

First verify:

```bash id="b7w33m"
echo $PRIV_VPC
echo $PUB_VPC
```

If empty, re-export them.

You already have:

```bash id="s5zk7o"
export PRIV_VPC=vpc-0eef4d7687dd46c95
```

Now find the public VPC ID:

```bash id="t2m89r"
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=datacenter-pub-vpc" \
  --query "Vpcs[0].VpcId" \
  --output text
```

Copy the output and export it:

Example:

```bash id="pu5b44"
export PUB_VPC=vpc-xxxxxxxx
```

Now create peering again:

```bash id="jj31du"
PEER=$(aws ec2 create-vpc-peering-connection \
  --vpc-id $PRIV_VPC \
  --peer-vpc-id $PUB_VPC \
  --query "VpcPeeringConnection.VpcPeeringConnectionId" \
  --output text)

echo $PEER
```

Then accept:

```bash id="drjlta"
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id $PEER
```

After that continue with route creation.
