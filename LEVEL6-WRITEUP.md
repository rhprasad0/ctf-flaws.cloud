# Level 6 Writeup - IAM Policy Enumeration & API Gateway Discovery

## Challenge URL
http://level6-cc4c404a8a8b876167f5e70a7d8c9880.flaws.cloud/

## Challenge Description
For this final challenge, you're given IAM user credentials with the SecurityAudit policy attached. The goal is to see what you can find in this AWS account and discover the hidden sub-directory.

## Solution

### Step 1: Initial Reconnaissance with Pacu

Started a Pacu session and configured the provided credentials:

```
Pacu > set_keys
Key alias: level6
Access key ID: AKIAJFQ6E7BY57Q3OBGA
Secret access key: [REDACTED]
```

### Step 2: Enumerate IAM Permissions

Used Pacu's `iam__enum_permissions` module to discover what the Level6 user can do:

```
Pacu > run iam__enum_permissions
[iam__enum_permissions] 1428 Confirmed permissions for user: Level6.
```

The `whoami` command revealed two attached policies:
- `MySecurityAudit` - A SecurityAudit-style policy with extensive read permissions
- `list_apigateways` - Custom policy for API Gateway access

Key permissions included:
- IAM read access (`iam:list*`, `iam:get*`)
- Lambda read access (`lambda:listfunctions`, `lambda:getpolicy`)
- API Gateway access (`apigateway:get` on `restapis/*`)

### Step 3: Enumerate IAM Users, Roles, and Policies

```
Pacu > run iam__enum_users_roles_policies_groups
[iam__enum_users_roles_policies_groups] Found 2 users
[iam__enum_users_roles_policies_groups] Found 10 roles
[iam__enum_users_roles_policies_groups] Found 9 policies
```

Key discovery: A role named `Level6` with a trust policy allowing `lambda.amazonaws.com` to assume it - indicating a Lambda function.

### Step 4: Discover Lambda Functions

```bash
aws lambda list-functions
```

Found a Lambda function:
- **Function Name:** `Level6`
- **ARN:** `arn:aws:lambda:us-west-2:975426262029:function:Level6`
- **Runtime:** Python 2.7
- **Role:** `arn:aws:iam::975426262029:role/service-role/Level6`

### Step 5: Get Lambda Resource Policy

```bash
aws lambda get-policy --function-name Level6
```

The policy revealed that API Gateway can invoke this Lambda:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "apigateway.amazonaws.com"
  },
  "Action": "lambda:InvokeFunction",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:execute-api:us-west-2:975426262029:s33ppypa75/*/GET/level6"
    }
  }
}
```

**Critical information extracted:**
- API Gateway ID: `s33ppypa75`
- HTTP Method: `GET`
- Path: `/level6`

### Step 6: Enumerate API Gateway Stage

```bash
aws apigateway get-stages --rest-api-id s33ppypa75
```

Output:
```json
{
    "item": [
        {
            "stageName": "Prod",
            ...
        }
    ]
}
```

### Step 7: Invoke the API Gateway Endpoint

Constructed the full API Gateway URL:
```
https://s33ppypa75.execute-api.us-west-2.amazonaws.com/Prod/level6
```

```bash
curl https://s33ppypa75.execute-api.us-west-2.amazonaws.com/Prod/level6
```

Response:
```
"Go to http://theend-797237e8ada164bf9f12cebf93b282cf.flaws.cloud/d730aa2b/"
```

### Step 8: Access the Final Page

Navigating to `http://theend-797237e8ada164bf9f12cebf93b282cf.flaws.cloud/d730aa2b/` completed the challenge!

## Key Techniques Used

1. **IAM Enumeration** - Using Pacu to enumerate all permissions, users, roles, and policies
2. **Lambda Discovery** - Finding Lambda functions and their configurations
3. **Resource Policy Analysis** - Extracting API Gateway details from Lambda resource policies
4. **API Gateway Enumeration** - Discovering stages and constructing endpoint URLs

## Lesson Learned

> It is common to give people and entities read-only permissions such as the SecurityAudit policy. The ability to read your own and other's IAM policies can really help an attacker figure out what exists in your environment and look for weaknesses and mistakes.

## How to Avoid This Mistake

- Don't hand out permissions liberally, even read-only ones
- Audit what information can be gleaned from "harmless" read permissions
- Apply least privilege - only grant the specific permissions needed
- Be aware that metadata and configuration information can reveal attack paths

## Tools Used

- **Pacu** - AWS exploitation framework for IAM enumeration
- **AWS CLI** - For Lambda and API Gateway enumeration
- **curl** - For invoking the API Gateway endpoint

## Credentials Found (Redacted)

```
Access Key ID: AKIAJFQ6E7BY57Q3OBGA
Secret Access Key: [REDACTED - 40 character key]
```

## AWS Resources Discovered

| Resource Type | Name/ID | Notes |
|--------------|---------|-------|
| IAM User | Level6 | SecurityAudit + list_apigateways policies |
| IAM Role | Level6 | Lambda execution role |
| Lambda Function | Level6 | Python 2.7, 282 bytes |
| API Gateway | s33ppypa75 | "Level6" API |
| API Stage | Prod | Production deployment |

## Attack Path Summary

```
IAM User Credentials
        ↓
IAM Permission Enumeration (Pacu)
        ↓
Discover Lambda Function (aws lambda list-functions)
        ↓
Get Lambda Resource Policy (aws lambda get-policy)
        ↓
Extract API Gateway ID from SourceArn
        ↓
Enumerate API Gateway Stages
        ↓
Construct & Call API Endpoint
        ↓
🎉 Challenge Complete!
```

---

## Collaboration Notes

This challenge was completed collaboratively with **Claude (Anthropic AI assistant)** in Cursor IDE. Claude helped with:

- Interpreting the massive 1400+ permission output from Pacu's `whoami` command
- Filtering and highlighting relevant IAM and Lambda permissions from the noise
- Parsing and explaining the Lambda resource policy JSON
- Identifying the API Gateway ID embedded in the SourceArn condition
- Constructing the final API Gateway URL format
- Debugging a credential issue (missing character in the secret key)

The human-AI pair programming approach was particularly effective for this challenge due to the large amount of JSON data that needed to be parsed and the multi-step discovery process across IAM → Lambda → API Gateway.

---

*Completed as part of the flaws.cloud CTF challenge series.*

