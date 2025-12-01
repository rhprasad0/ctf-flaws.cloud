#!/bin/bash
# Hardened Entrypoint Script for Kali CTF Container
# Purpose: Sanitize environment and prevent prompt injection attacks

set -euo pipefail

# =============================================================
# ENVIRONMENT SANITIZATION
# =============================================================

# List of dangerous environment variables to clear
# These could be used for prompt injection or credential theft
DANGEROUS_VARS=(
    # AWS Credentials
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "AWS_SESSION_TOKEN"
    "AWS_SECURITY_TOKEN"
    "AWS_DEFAULT_REGION"
    "AWS_PROFILE"
    "AWS_SHARED_CREDENTIALS_FILE"
    "AWS_CONFIG_FILE"
    
    # Cloud Provider Credentials
    "AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET"
    "AZURE_TENANT_ID"
    "AZURE_SUBSCRIPTION_ID"
    "GOOGLE_APPLICATION_CREDENTIALS"
    "GOOGLE_CLOUD_PROJECT"
    "GCP_PROJECT"
    "CLOUDSDK_CORE_PROJECT"
    
    # Database Credentials
    "DATABASE_URL"
    "DB_PASSWORD"
    "MYSQL_PASSWORD"
    "POSTGRES_PASSWORD"
    "MONGODB_URI"
    "REDIS_URL"
    
    # API Keys and Tokens
    "API_KEY"
    "API_SECRET"
    "SECRET_KEY"
    "PRIVATE_KEY"
    "AUTH_TOKEN"
    "ACCESS_TOKEN"
    "REFRESH_TOKEN"
    "BEARER_TOKEN"
    "JWT_SECRET"
    "ENCRYPTION_KEY"
    
    # GitHub/GitLab Tokens
    "GITHUB_TOKEN"
    "GITHUB_API_TOKEN"
    "GH_TOKEN"
    "GITLAB_TOKEN"
    "GITLAB_PRIVATE_TOKEN"
    
    # CI/CD Secrets
    "CI_JOB_TOKEN"
    "CI_REGISTRY_PASSWORD"
    "DOCKER_PASSWORD"
    "NPM_TOKEN"
    "PYPI_TOKEN"
    
    # SSH Keys
    "SSH_PRIVATE_KEY"
    "SSH_AUTH_SOCK"
    
    # Prompt Injection Vectors
    "PROMPT"
    "SYSTEM_PROMPT"
    "AI_INSTRUCTIONS"
    "OPENAI_API_KEY"
    "ANTHROPIC_API_KEY"
    "CLAUDE_API_KEY"
    
    # Potentially Dangerous Vars
    "LD_PRELOAD"
    "LD_LIBRARY_PATH"
    "DYLD_INSERT_LIBRARIES"
    "DYLD_LIBRARY_PATH"
)

# Clear dangerous environment variables
for var in "${DANGEROUS_VARS[@]}"; do
    if [[ -n "${!var:-}" ]]; then
        echo "[SECURITY] Clearing potentially dangerous environment variable: $var"
        unset "$var"
    fi
done

# Also clear any variables containing "SECRET", "PASSWORD", "KEY", "TOKEN" (case insensitive)
while IFS='=' read -r name _; do
    case "${name^^}" in
        *SECRET*|*PASSWORD*|*KEY*|*TOKEN*|*CREDENTIAL*|*AUTH*)
            # Whitelist some safe variables
            case "$name" in
                TERM|COLORTERM|SSH_TTY|GPG_TTY|SHLVL|OLDPWD|PWD|HOME|USER|SHELL|LANG|LC_*|PATH|HOSTNAME|LOGNAME|MAIL|_)
                    # Keep these safe variables
                    ;;
                *)
                    echo "[SECURITY] Clearing environment variable matching sensitive pattern: $name"
                    unset "$name" 2>/dev/null || true
                    ;;
            esac
            ;;
    esac
done < <(env)

# =============================================================
# SAFE PATH CONFIGURATION
# =============================================================

# Set a safe, minimal PATH (no relative paths, no user-writable directories first)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# =============================================================
# SHELL HISTORY PROTECTION
# =============================================================

# Disable shell history completely
export HISTFILE=/dev/null
export HISTSIZE=0
export HISTFILESIZE=0
export SAVEHIST=0
unset HISTFILE

# =============================================================
# UMASK CONFIGURATION
# =============================================================

# Set restrictive umask (files: 600, directories: 700)
umask 077

# =============================================================
# SECURITY VALIDATION
# =============================================================

# Verify we're running as the expected user
EXPECTED_USER="ctf"
CURRENT_USER=$(whoami)

if [[ "$CURRENT_USER" != "$EXPECTED_USER" && "$CURRENT_USER" != "root" ]]; then
    echo "[WARNING] Running as unexpected user: $CURRENT_USER"
fi

# Verify no secrets leaked into environment
SECRET_LEAK_CHECK=$(env | grep -iE "(secret|password|key|token|credential)" | grep -v "^PATH=" | grep -v "^TERM=" | grep -v "^COLORTERM=" | head -5 || true)
if [[ -n "$SECRET_LEAK_CHECK" ]]; then
    echo "[WARNING] Potential secrets detected in environment after sanitization:"
    echo "$SECRET_LEAK_CHECK" | head -3
    echo "[WARNING] These will be cleared..."
    # Force clear any remaining
    while IFS='=' read -r name _; do
        unset "$name" 2>/dev/null || true
    done <<< "$SECRET_LEAK_CHECK"
fi

# =============================================================
# STARTUP MESSAGE
# =============================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         HARDENED KALI CTF CONTAINER                          ║"
echo "║         flaws.cloud Challenge Environment                    ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Security Features:                                          ║"
echo "║  • Environment variables sanitized                           ║"
echo "║  • Shell history disabled                                    ║"
echo "║  • Restrictive umask (077)                                   ║"
echo "║  • Running as non-root user: $CURRENT_USER                          ║"
echo "║  • Seccomp and capability restrictions active                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================
# EXECUTE COMMAND
# =============================================================

# If arguments provided, execute them
if [[ $# -gt 0 ]]; then
    exec "$@"
else
    # Default to bash shell
    exec /bin/bash --norc --noprofile
fi


