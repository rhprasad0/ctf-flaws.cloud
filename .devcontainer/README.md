# Hardened Kali CTF Container for flaws.cloud

A security-hardened Kali Linux development container specifically designed for completing the [flaws.cloud](http://flaws.cloud) capture the flag challenges, with comprehensive defenses against prompt injection attacks.

## Quick Start

### Using Cursor/VS Code

1. Install the "Dev Containers" extension
2. Open this folder in Cursor/VS Code
3. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
4. Select "Dev Containers: Reopen in Container"
5. Wait for the build to complete (2-3 minutes for first build)

### Using Docker CLI

```bash
cd .devcontainer
docker compose up -d
docker compose exec kali-ctf /bin/bash
```

## Security Features

### Prompt Injection Defenses

| Attack Vector | Mitigation |
|--------------|------------|
| Environment variable leakage | Entrypoint sanitizes all sensitive env vars (AWS keys, tokens, secrets) |
| File exfiltration | Read-only root filesystem, workspace-only write access |
| Network attacks | Custom bridge network, no `--network=host` |
| Container escape | Seccomp syscall filtering, capability dropping, no-new-privileges |
| History leakage | Shell history completely disabled |

### Container Hardening

- **Non-root user**: Runs as `ctf` user with sudo access when needed
- **Read-only filesystem**: Root filesystem is read-only with tmpfs for `/tmp`, `/var/tmp`, `/run`
- **Dropped capabilities**: All capabilities dropped except `NET_RAW` and `NET_ADMIN` (required for nmap)
- **Seccomp profile**: Custom profile blocking dangerous syscalls (ptrace, mount, keyctl, etc.)
- **AppArmor profile**: Optional MAC policy for additional file and network restrictions
- **Resource limits**: CPU and memory limits to prevent DoS

### Environment Sanitization

The entrypoint script automatically clears:
- AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, etc.)
- Cloud provider credentials (Azure, GCP)
- Database credentials
- API keys and tokens
- AI/LLM API keys (OpenAI, Anthropic, etc.)
- Any variable containing "SECRET", "PASSWORD", "KEY", or "TOKEN"

## Included Tools

The container includes a minimal toolset for fast builds. Pre-installed:

- **Network**: nmap, netcat, dnsutils, ping, iproute2
- **Utilities**: curl, wget, git, vim, less, file
- **AWS**: awscli (for flaws.cloud challenges)
- **Scripting**: python3, pip

### Installing Additional Tools

Add tools as needed:
```bash
sudo apt update && sudo apt install <package>
```

Common additions for CTF work:
```bash
# Web testing
sudo apt install gobuster nikto dirb sqlmap

# Password cracking
sudo apt install john hashcat hydra

# Forensics
sudo apt install binwalk foremost

# Full Kali toolset (if needed)
sudo apt install kali-linux-default
```

## Optional: AppArmor Profile

For additional security, you can load the AppArmor profile on your host:

```bash
# Load the profile
sudo cp .devcontainer/apparmor-profile /etc/apparmor.d/kali-ctf-hardened
sudo apparmor_parser -r /etc/apparmor.d/kali-ctf-hardened

# Then uncomment the apparmor line in docker-compose.yml:
# - apparmor=kali-ctf-hardened
```

## Directory Structure

```
.devcontainer/
├── Dockerfile          # Kali Linux image with security hardening
├── devcontainer.json   # VS Code/Cursor integration
├── docker-compose.yml  # Runtime security configuration
├── entrypoint.sh       # Environment sanitization script
├── seccomp.json        # Syscall filtering profile
└── apparmor-profile    # Optional MAC policy
```

## Troubleshooting

### Build fails with package errors
The Kali repositories may be temporarily unavailable. Wait a few minutes and try again.

### Permission denied errors
Ensure the entrypoint script is executable:
```bash
chmod +x .devcontainer/entrypoint.sh
```

### Network tools not working
Some tools like nmap require the `NET_RAW` capability. This is already enabled in the compose file.

### Need to install additional packages
The container runs with a read-only filesystem, but package installation is supported via mounted volumes:
```bash
sudo apt update && sudo apt install <package>
```

## Security Notes

- **Do not mount your host's AWS credentials** into this container
- **Do not use `--network=host`** as it bypasses network isolation
- **Do not run with `--privileged`** as it disables all security features
- The container is designed to be disposable - rebuild rather than accumulate state

## License

MIT License - Use at your own risk for educational purposes only.


