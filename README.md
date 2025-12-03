# flaws.cloud CTF Challenge

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   🚨🚨🚨 DANGER ZONE 🚨🚨🚨                                                  ║
║                                                                              ║
║   ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗ ██╗             ║
║   ██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝ ██║             ║
║   ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗██║             ║
║   ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║╚═╝             ║
║   ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝██╗             ║
║    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝             ║
║                                                                              ║
║   🎭 THIS REPOSITORY CONTAINS SPOILERS FOR FLAWS.CLOUD 🎭                   ║
║                                                                              ║
║   If you haven't tried the challenges yet, TURN BACK NOW!                   ║
║   Go to http://flaws.cloud and struggle gloriously on your own first.       ║
║                                                                              ║
║   Seriously. The writeups in here will RUIN the fun.                        ║
║   You'll rob yourself of those sweet, sweet "AHA!" moments.                 ║
║   Your future self will be disappointed in you.                             ║
║   Your ancestors will shake their heads in disapproval.                     ║
║                                                                              ║
║   Still here? Don't say we didn't warn you... 👀                            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

A hands-on learning environment for AWS security through the [flaws.cloud](http://flaws.cloud) capture the flag challenges.

## About flaws.cloud

flaws.cloud is a free AWS security CTF created by Scott Piper of Summit Route. It teaches common AWS misconfigurations and security issues through a series of progressive challenges. Each level builds on concepts from the previous ones, teaching real-world cloud security skills.

## Learning Goals

This project is designed for **learning by doing**. The goal is not just to capture flags, but to:

- Understand how AWS services like S3, EC2, and IAM work
- Recognize common cloud security misconfigurations
- Learn to use AWS CLI and security tools effectively
- Develop a methodical approach to cloud security assessment
- Build intuition for where security weaknesses hide

## Quick Start

This repository includes a hardened Kali Linux development container with the tools you need.

1. Install the "Dev Containers" extension in VS Code/Cursor
2. Open this folder and select "Reopen in Container"
3. Navigate to [http://flaws.cloud](http://flaws.cloud) to begin

For detailed container setup, see [.devcontainer/README.md](.devcontainer/README.md).

## Challenge Levels

flaws.cloud consists of 6 levels, each teaching different AWS security concepts:

| Level | Topic | Description |
|-------|-------|-------------|
| 1 | S3 Basics | Understanding S3 bucket fundamentals |
| 2 | S3 Permissions | Exploring bucket permission models |
| 3 | S3 Enumeration | Discovering hidden resources |
| 4 | EC2 Snapshots | Working with EBS snapshots |
| 5 | EC2 Metadata | Understanding instance metadata |
| 6 | IAM Roles | Role assumption and privilege escalation |

## Progress Tracking

Track your progress through the challenges:

- [x] **Level 1** - S3 bucket basics
- [x] **Level 2** - S3 permissions
- [x] **Level 3** - S3 bucket enumeration
- [x] **Level 4** - EC2 snapshots
- [x] **Level 5** - EC2 metadata (SSRF)
- [ ] **Level 6** - IAM role assumption

## Working with an AI Agent

If you're using an AI coding assistant (like Cursor), please read [AGENTS.md](AGENTS.md) for guidelines on collaborative learning. The agent is configured to help you learn without spoiling the challenges.

## AWS Documentation Resources

These official resources will help you understand the AWS services involved:

- [Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/)
- [Amazon EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/)
- [Instance Metadata and User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)

## Tips for Success

1. **Read carefully** - Each level's page contains hints in plain sight
2. **Take notes** - Document what you discover and learn
3. **Experiment** - Try different approaches and observe the results
4. **Understand, don't just solve** - The goal is learning, not speed
5. **Use the tools** - AWS CLI, nmap, curl, and dig are your friends

---

*Remember: The journey matters more than the destination. Take time to understand each vulnerability before moving on.*


