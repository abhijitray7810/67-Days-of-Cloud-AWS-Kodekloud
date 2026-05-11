Your template looks correct. The issue is that the stack was still in `CREATE_IN_PROGRESS` state when you tried `get-function`.

Wait 1–2 minutes and run:

```bash
aws cloudformation describe-stacks \
  --stack-name nautilus-lambda-app \
  --region us-east-1 \
  --query "Stacks[0].StackStatus"
```

If successful, it should show:

```bash
"CREATE_COMPLETE"
```

Then verify the Lambda again:

```bash
aws lambda get-function \
  --function-name nautilus-lambda \
  --region us-east-1
```

If the stack fails, check the events:

```bash
aws cloudformation describe-stack-events \
  --stack-name nautilus-lambda-app \
  --region us-east-1
```

Most likely it will complete successfully because your YAML is valid.
