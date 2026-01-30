# mgn-windows-agent

Repo details the steps to deploy the AWS MGN Agent to Windows servers with secure automation

## Prep

Create an IAM Role with the following policy

**Permissions Policy:**
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:*",
                "ssmmessages:*",
                "ec2messages:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "mgn:RegisterAgentForMgn",
                "mgn:SendAgentMetricsForMgn",
                "mgn:SendAgentLogsForMgn",
                "mgn:SendChannelCommandResultForMgn",
                "mgn:SendClientLogsForMgn",
                "mgn:GetChannelCommandsForMgn"
            ],
            "Resource": "*"
        }
    ]
}
```

**Trust Policy:**
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ssm.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

Setup the AWS SSM Hybrid Activation

```bash
# Run this from a machine with AWS CLI configured and save output
# IMPORTANT: Save the ActivationId and ActivationCode from the command output
aws ssm create-activation \
    --iam-role "SSM-Hybrid-Agent" \
    --registration-limit 100 \
    --expiration-date $(date -v+7d +'%Y-%m-%dT%H:%M:%S') \
    --region us-west-2
```

## Install MGN via bootstrap-mgn.ps1