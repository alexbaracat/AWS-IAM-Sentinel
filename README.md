# AWS IAM Sentinel


An event-driven security monitor for AWS Identity and Access Management (IAM). It watches every IAM API call recorded by CloudTrail, picks out the high-risk ones (new users, new access keys, policy changes and similar), and sends an alert to Slack and to an SNS topic within seconds. The whole stack is defined as code with Terraform.


## Why this exists


IAM changes are one of the most common ways an AWS account gets compromised or quietly weakened: an attacker creates a user, mints an access key, or attaches an admin policy. Reviewing CloudTrail logs by hand does not scale. IAM Sentinel turns those log entries into a real-time signal so the person responsible hears about a risky change as it happens.


## How it works


```
IAM API call
    |
    v
CloudTrail (trail writes logs to a private S3 bucket)
    |
    v
EventBridge rule  (source: aws.iam, detail-type: "AWS API Call via CloudTrail")
    |
    v
Lambda: iam-sentinel-detector  (Python 3.12)
    |-- event is in the high-risk list --> Slack message + SNS notification
    |-- anything else                  --> logged and ignored
```


1. **CloudTrail** records IAM activity and stores the logs in an S3 bucket created by the project. The bucket name gets a random suffix so it is globally unique, and a bucket policy lets only the CloudTrail service write to it.
2. **EventBridge** matches API calls coming from the IAM service and triggers the Lambda function for each one.
3. **Lambda** (lambda/handler.py) reads the event, pulls out the event name, the caller's ARN, the source IP and the request parameters, and checks the event name against a list of high-risk actions. For a match it builds an alert with severity HIGH.
4. **Slack and SNS**: the alert is posted to a Slack incoming webhook as a formatted message with the request parameters in a JSON block, and is also published to the SNS topic iam-sentinel-alerts so you can subscribe email, SMS or other consumers. If either destination is not configured or fails, the function logs the problem and carries on with the other.


## What counts as high risk


The detector currently flags these IAM events:


| Event | Why it matters |
| --- | --- |
| CreateUser, DeleteUser | Identities appearing or disappearing outside normal change control |
| CreateAccessKey | New long-lived credentials, a classic persistence technique |
| PutUserPolicy, AttachUserPolicy | Permissions granted directly to a user |
| AttachGroupPolicy | Permissions changed for everyone in a group |
| AttachRolePolicy | Permissions added to a role |
| UpdateAssumeRolePolicy | Changes who is allowed to assume a role |
| AddUserToGroup, RemoveUserFromGroup | Privilege changes through group membership |


All other IAM events are logged and ignored. To change the rules, edit the HIGH_RISK_EVENTS list in lambda/handler.py.


## Project structure


```
AWS-IAM-Sentinel/
|-- lambda/
|   |-- handler.py          # Detection and alerting logic
|-- terraform/
    |-- main.tf             # Terraform and AWS provider setup (us-east-1)
    |-- cloudtrail.tf       # CloudTrail trail, S3 log bucket and bucket policy
    |-- eventbridge.tf      # Rule that forwards IAM API calls to the Lambda
    |-- lambda.tf           # Packages and deploys the detector function
    |-- iam.tf              # Execution role and permissions for the Lambda
    |-- sns.tf              # SNS topic for alerts
    |-- variables.tf        # Inputs (Slack webhook URL)
```


## Deploying it


You need Terraform 1.3 or newer, AWS credentials with permission to create the resources above, and a Slack incoming webhook URL.


```bash
cd terraform
terraform init
terraform apply -var="slack_webhook=https://hooks.slack.com/services/XXX/YYY/ZZZ"
```


Terraform zips the lambda folder, creates the Lambda function with SLACK_WEBHOOK and SNS_TOPIC_ARN as environment variables, and wires everything together. To receive SNS notifications by email, subscribe an address to the iam-sentinel-alerts topic in the AWS console.


To clean up, run terraform destroy. The log bucket is created with force_destroy enabled, so it is removed along with its contents.


## Testing it


Create and delete a throwaway IAM user, or create an access key for a test user. Within a short time you should see a message in Slack, and the function's logs in CloudWatch will show the received event and whether it was alerted or ignored.


## Skills demonstrated


Event-driven architecture on AWS, infrastructure as code with Terraform, IAM roles and managed policies for the Lambda function, CloudTrail and EventBridge integration, serverless Python with boto3, and alert delivery through Slack and SNS.


## Possible improvements


- Add severity levels instead of a single HIGH category
- Route alerts for root-account activity separately
- Enable CloudTrail log file validation and S3 encryption
- Add unit tests for the event-matching logic
- Replace the broad AmazonSNSFullAccess policy on the Lambda role with a policy scoped to publishing on the one alerts topic

