# mgn-windows-agent

Repo details the steps to deploy the AWS MGN Agent to Windows servers with secure automation

## Prep

Setup the AWS SSM Hybrid Activation

```# Run this from a machine with AWS CLI configured and save output
aws ssm create-activation `
    --default-instance-name "MGN-Migration-Server" `
    --iam-role "SSMServiceRole" `
    --registration-limit 100 `
    --expiration-date (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss") `
    --region [region]

```

Create an IAM Role with the following policy

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

## Install MGN via bootstrap-mgn.ps1