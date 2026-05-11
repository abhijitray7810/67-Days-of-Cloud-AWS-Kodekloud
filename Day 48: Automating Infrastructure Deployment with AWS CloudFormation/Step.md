```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: CloudFormation template to create Lambda function and IAM role

Resources:

  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: lambda_execution_role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action:
              - sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

  NautilusLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: nautilus-lambda
      Runtime: python3.9
      Handler: index.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Timeout: 10
      Code:
        ZipFile: |
          import json

          def lambda_handler(event, context):
              return {
                  'statusCode': 200,
                  'body': 'Welcome to KKE AWS Labs!'
              }

Outputs:
  LambdaFunctionName:
    Value: !Ref NautilusLambda
```

Run these commands on the `aws-client` host:

```bash
cat > /root/nautilus-lambda.yml <<'EOF'
PASTE_THE_TEMPLATE_HERE
EOF
```

Then deploy the stack:

```bash
aws configure
```

(Use credentials from `showcreds`)

Then create the stack:

```bash
aws cloudformation create-stack \
  --stack-name nautilus-lambda-app \
  --template-body file:///root/nautilus-lambda.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

Verify:

```bash
aws cloudformation describe-stacks \
  --stack-name nautilus-lambda-app \
  --region us-east-1
```

And check Lambda:

```bash
aws lambda get-function \
  --function-name nautilus-lambda \
  --region us-east-1
```
