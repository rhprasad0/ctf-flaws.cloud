# Level 2 Writeup - Authenticated AWS Users

**Completed:** December 2, 2025  
**Assisted by:** Claude (AI pair programming assistant)

---

## Challenge Overview

Level 2 builds on the S3 bucket misconfiguration theme from Level 1, but with a twist: anonymous access is blocked. The challenge requires understanding the difference between "Everyone" and "Any Authenticated AWS User" permissions.

## Approach

### Step 1: Applying Level 1 Knowledge

Based on what we learned in Level 1, we knew:
- The bucket name matches the domain: `level2-c8b217a33fcf1f839f6f1f73a00a9ae7.flaws.cloud`
- We could try listing the bucket with the AWS CLI

### Step 2: Testing Anonymous Access

First, we tried the same approach that worked in Level 1:

```bash
aws s3 ls s3://level2-c8b217a33fcf1f839f6f1f73a00a9ae7.flaws.cloud --no-sign-request
```

**Result:** `Access Denied`

This confirmed that anonymous/unauthenticated access was blocked - the "twist" mentioned in the challenge.

### Step 3: Understanding the Hint

The challenge page stated: "You're going to need your own AWS account for this."

This suggested the bucket might allow access to **authenticated AWS users** rather than anonymous users.

### Step 4: Testing Authenticated Access

We removed the `--no-sign-request` flag to use our configured AWS credentials:

```bash
aws s3 ls s3://level2-c8b217a33fcf1f839f6f1f73a00a9ae7.flaws.cloud
```

**Result:**
```
2017-02-27 02:02:15      80751 everyone.png
2017-03-03 03:47:17       1433 hint1.html
2017-02-27 02:04:39       1035 hint2.html
2017-02-27 02:02:14       2786 index.html
2017-02-27 02:02:14         26 robots.txt
2017-02-27 02:02:15       1051 secret-e4443fc.html
```

Success! The bucket allowed listing with any valid AWS credentials.

### Step 5: Accessing the Secret File

We navigated to `http://level2-c8b217a33fcf1f839f6f1f73a00a9ae7.flaws.cloud/secret-e4443fc.html` to find the URL for Level 3.

## Tools Used

| Tool | Purpose |
|------|---------|
| `aws s3 ls` | Listing S3 bucket contents (authenticated) |
| Web browser | Viewing the secret page |

## Vulnerability Explained

**The Misconfiguration:** The S3 bucket was configured to allow **"Any Authenticated AWS User"** to list its contents, rather than "Everyone" (anonymous).

**Why This Is Still Dangerous:**

| Permission | Who Can Access |
|------------|----------------|
| Everyone | Anyone on the internet, no account needed |
| Any Authenticated AWS User | Anyone with ANY AWS account (free to create) |
| Specific AWS accounts/users | Only designated principals |

The "Any Authenticated AWS User" permission sounds restrictive but is effectively public access. AWS accounts are free, so anyone can create one and gain access.

**Common Misconception:** Developers sometimes think "authenticated" means "users in my organization" when it actually means "any of the millions of AWS account holders worldwide."

**How to Prevent This:**
- Never use "Any Authenticated AWS User" for sensitive resources
- Use specific IAM principals (accounts, users, roles) in bucket policies
- Implement least-privilege access principles
- Use AWS Organizations SCPs to restrict cross-account access
- Regularly audit S3 bucket policies and ACLs

## Key Takeaways

1. "Any Authenticated AWS User" ≠ "My organization's users"
2. The `--no-sign-request` flag controls whether AWS CLI uses credentials
3. S3 permissions have multiple levels of "public" access
4. Always use specific IAM principals instead of broad authenticated user access
5. The `everyone.png` file in the bucket was a clever hint about the misconfiguration

## Comparison: Level 1 vs Level 2

| Aspect | Level 1 | Level 2 |
|--------|---------|---------|
| Access Type | Anonymous (Everyone) | Any Authenticated AWS User |
| CLI Flag | `--no-sign-request` | (no flag - uses credentials) |
| AWS Account Required | No | Yes |
| Effective Security | None | Minimal |


