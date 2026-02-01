# mgn-windows-agent

Repo details the steps to deploy the AWS MGN Agent to Windows servers with secure automation

## Prep

Create an IAM Role with the following policy Named "SSM-Hybrid-Agent"

**SSM-Hybrid-Agent Permissions Policy:**
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::[accnt_number]:role/MGN-Agent"
        }
    ]
}
```

**SSM-Hybrid-Agent Trust Policy:**
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

Create an IAM Role with the following policy Named "MGN-Agent"

**MGN-Agent Permissions Policy:**
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mgn:GetAgentInstallationAssetsForMgn",
                "mgn:SendClientMetricsForMgn",
                "mgn:SendClientLogsForMgn",
                "mgn:RegisterAgentForMgn",
                "mgn:VerifyClientRoleForMgn"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "mgn:IssueClientCertificateForMgn"
            ],
            "Resource": "arn:aws:mgn:*:*:source-server/*"
        },
        {
            "Effect": "Allow",
            "Action": "mgn:TagResource",
            "Resource": "arn:aws:mgn:*:*:source-server/*"
        },
                {
            "Effect": "Allow",
            "Action": [
                "mgn:SendAgentMetricsForMgn",
                "mgn:SendAgentLogsForMgn",
                "mgn:SendClientMetricsForMgn",
                "mgn:SendClientLogsForMgn"
            ],
            "Resource": "*"
        },
                {
            "Effect": "Allow",
            "Action": [
                "mgn:RegisterAgentForMgn",
                "mgn:UpdateAgentSourcePropertiesForMgn",
                "mgn:UpdateAgentReplicationInfoForMgn",
                "mgn:UpdateAgentConversionInfoForMgn",
                "mgn:GetAgentInstallationAssetsForMgn",
                "mgn:GetAgentCommandForMgn",
                "mgn:GetAgentConfirmedResumeInfoForMgn",
                "mgn:GetAgentRuntimeConfigurationForMgn",
                "mgn:UpdateAgentBacklogForMgn",
                "mgn:GetAgentReplicationInfoForMgn"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::[accnt_number]:role/MGN-Agent"
        }
    ]
}
```

**SSM-Hybrid-Agent Trust Policy:**
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::[accnt_number]:role/SSM-Hybrid-Agent"
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

## Install MGN via bootstrap-mgn.ps1 on local Windows computer or remotely via remote-mgn-install.ps1

```
 .\remote-ssm-install.ps1 -ComputerName session1.domain1.lab,broker1.domain1.lab,broker2.domain1.lab -ActivationCode [ActivationCode] -ActivationId [ActiveationID] -Region [region]

```