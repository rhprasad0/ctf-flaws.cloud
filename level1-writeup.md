# Level 1 Writeup - S3 Bucket Basics

**Completed:** December 1, 2025  
**Assisted by:** Claude (AI pair programming assistant)

---

## Challenge Overview

The first level of flaws.cloud introduces S3 bucket misconfigurations. The goal was to find a hidden subdomain by exploring the infrastructure.

## Approach

### Step 1: Initial Reconnaissance

We started by visiting the main site at `http://flaws.cloud` and reading the challenge description. A key hint was provided:

> "This level is *buckets* of fun. See if you can find the first sub-domain."

The word "buckets" was a strong hint pointing toward AWS S3.

### Step 2: DNS Investigation

We used DNS tools to investigate how the site was hosted:

```bash
# Basic DNS lookup
dig flaws.cloud

# Reverse DNS lookup on returned IP addresses
host 52.92.179.187
```

The reverse DNS lookups revealed that all IPs pointed to:
- `s3-website-us-west-2.amazonaws.com`

This confirmed the site was hosted on **S3 static website hosting** in the **us-west-2** region.

### Step 3: Understanding S3 Website Hosting

Key insight: When using a custom domain with S3 static website hosting, the **bucket name must match the domain name exactly**.

Therefore: `flaws.cloud` (domain) → `flaws.cloud` (bucket name)

### Step 4: Listing the Bucket Contents

We attempted to list the bucket contents using the AWS CLI:

```bash
# First attempt (failed - no credentials configured)
aws s3 ls s3://flaws.cloud

# Second attempt (success - anonymous access)
aws s3 ls s3://flaws.cloud --no-sign-request
```

The `--no-sign-request` flag allows anonymous (unauthenticated) access to public buckets.

**Result:**
```
2017-03-14 03:00:38       2575 hint1.html
2017-03-03 04:05:17       1707 hint2.html
2017-03-03 04:05:11       1101 hint3.html
2024-02-22 02:32:41       2861 index.html
2018-07-10 16:47:16      15979 logo.png
2017-02-27 01:59:28         46 robots.txt
2017-02-27 01:59:30       1051 secret-dd02c7c.html
```

### Step 5: Accessing the Secret File

We navigated to `http://flaws.cloud/secret-dd02c7c.html` in the browser, which revealed the congratulations message and the URL for Level 2.

## Tools Used

| Tool | Purpose |
|------|---------|
| `dig` | DNS A record lookup |
| `host` | Reverse DNS lookups |
| `aws s3 ls` | Listing S3 bucket contents |
| Web browser | Viewing the secret page |

## Vulnerability Explained

**The Misconfiguration:** The S3 bucket had **public listing enabled**, allowing anyone to enumerate all files in the bucket without authentication.

**Why This Matters:** Even if sensitive files aren't linked from the website, an attacker can discover them by simply listing the bucket contents. Security through obscurity (hiding files with random names) doesn't work when the bucket allows public listing.

**How to Prevent This:**
- Disable public bucket listing
- Use S3 bucket policies to restrict access
- Enable S3 Block Public Access settings
- Audit bucket permissions regularly

## Key Takeaways

1. DNS reconnaissance can reveal hosting infrastructure details
2. S3 bucket names for website hosting match the domain name
3. The `--no-sign-request` flag enables anonymous S3 access
4. Public bucket listing is a common and dangerous misconfiguration

