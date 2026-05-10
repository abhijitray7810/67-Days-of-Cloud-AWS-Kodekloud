# Nautilus Priority Queue

AWS-based priority message queuing system using SNS, SQS, and Lambda. High-priority messages are always processed before low-priority messages.

## Architecture

```
Publisher
    │
    ▼
SNS Topic (nautilus-Priority-Queues-Topic)
    │
    ├──[priority=high]──▶ SQS High Priority Queue
    │                              │
    └──[priority=low]───▶ SQS Low Priority Queue
                                   │
                          Lambda polls high queue first,
                          falls back to low queue if empty
```

## Resources

| Resource | Name | Type |
|---|---|---|
| SNS Topic | nautilus-Priority-Queues-Topic | AWS::SNS::Topic |
| High Priority Queue | nautilus-High-Priority-Queue | AWS::SQS::Queue |
| Low Priority Queue | nautilus-Low-Priority-Queue | AWS::SQS::Queue |
| Lambda Function | nautilus-priorities-queue-function | AWS::Lambda::Function |
| IAM Role | lambda_execution_role | AWS::IAM::Role |
| IAM Managed Policy | lambda-sqs-sns-policy | AWS::IAM::ManagedPolicy |

## Files

```
.
├── nautilus-priority-stack.yml   # CloudFormation template
├── index.py                      # Lambda function source
└── README.md
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- IAM permissions: `cloudformation:*`, `sqs:*`, `sns:*`, `lambda:*`, `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:CreatePolicy`

## Deploy

```bash
aws cloudformation create-stack \
  --stack-name nautilus-priority-stack \
  --template-body file:///root/nautilus-priority-stack.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name nautilus-priority-stack \
  --region us-east-1
```

## Test

**1. Publish messages to the SNS topic:**

```bash
topicarn=$(aws sns list-topics \
  --query "Topics[?contains(TopicArn, 'nautilus-Priority-Queues-Topic')].TopicArn" \
  --output text)

aws sns publish --topic-arn $topicarn \
  --message 'High Priority message 1' \
  --message-attributes '{"priority":{"DataType":"String","StringValue":"high"}}'

aws sns publish --topic-arn $topicarn \
  --message 'High Priority message 2' \
  --message-attributes '{"priority":{"DataType":"String","StringValue":"high"}}'

aws sns publish --topic-arn $topicarn \
  --message 'Low Priority message 1' \
  --message-attributes '{"priority":{"DataType":"String","StringValue":"low"}}'

aws sns publish --topic-arn $topicarn \
  --message 'Low Priority message 2' \
  --message-attributes '{"priority":{"DataType":"String","StringValue":"low"}}'
```

**2. Invoke the Lambda function and observe priority ordering:**

```bash
for i in 1 2 3 4; do
  aws lambda invoke \
    --function-name nautilus-priorities-queue-function \
    /tmp/out.json && cat /tmp/out.json && echo
done
```

**Expected output** — high-priority messages are returned first:

```
"Message 'High Priority message 1' deleted"
"Message 'High Priority message 2' deleted"
"Message 'Low Priority message 1' deleted"
"Message 'Low Priority message 2' deleted"
```

## How It Works

1. Messages are published to the SNS topic with a `priority` message attribute set to `high` or `low`.
2. SNS filter policies route each message to the correct SQS queue.
3. When the Lambda function is invoked, it polls the **high-priority queue first**.
4. Only if the high-priority queue is empty does it fall back to the **low-priority queue**.
5. Each invocation processes and deletes exactly one message.

## Teardown

```bash
aws cloudformation delete-stack \
  --stack-name nautilus-priority-stack \
  --region us-east-1

aws cloudformation wait stack-delete-complete \
  --stack-name nautilus-priority-stack \
  --region us-east-1
```
