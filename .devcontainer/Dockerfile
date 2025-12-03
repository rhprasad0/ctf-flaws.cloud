# Hardened Kali Linux Development Container for CTF
# Optimized for flaws.cloud challenges with prompt injection defenses

FROM kalilinux/kali-rolling:latest

LABEL maintainer="CTF Security Container"
LABEL description="Hardened Kali Linux container for flaws.cloud CTF"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install minimal toolset
# Add tools as needed with: sudo apt install <package>
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        # Essential utilities
        sudo \
        ca-certificates \
        locales \
        curl \
        wget \
        git \
        vim \
        less \
        file \
        # Networking basics
        nmap \
        netcat-openbsd \
        dnsutils \
        iputils-ping \
        iproute2 \
        openssh-client \
        # AWS CLI for flaws.cloud challenges
        awscli \
        # Python for scripting
        python3 \
        python3-pip \
        pipx \
        && \
    # Generate locale
    sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    # Clean up to reduce image size
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create non-root user 'ctf' with sudo access
RUN useradd -m -s /bin/bash -G sudo ctf && \
    echo "ctf ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ctf && \
    chmod 0440 /etc/sudoers.d/ctf

# Security hardening: Disable shell history for all users
RUN echo 'HISTFILE=/dev/null' >> /etc/bash.bashrc && \
    echo 'HISTSIZE=0' >> /etc/bash.bashrc && \
    echo 'HISTFILESIZE=0' >> /etc/bash.bashrc && \
    echo 'unset HISTFILE' >> /etc/bash.bashrc && \
    # Also for zsh if present
    echo 'HISTFILE=/dev/null' >> /etc/zsh/zshrc 2>/dev/null || true && \
    echo 'HISTSIZE=0' >> /etc/zsh/zshrc 2>/dev/null || true && \
    echo 'SAVEHIST=0' >> /etc/zsh/zshrc 2>/dev/null || true

# Security hardening: Set restrictive umask
RUN echo 'umask 077' >> /etc/bash.bashrc && \
    echo 'umask 077' >> /etc/zsh/zshrc 2>/dev/null || true

# Security hardening: Clear environment on shell exit
RUN echo 'trap "unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN" EXIT' >> /etc/bash.bashrc

# Security hardening: Remove potentially dangerous SUID binaries
RUN find /usr -perm /4000 -type f 2>/dev/null | \
    grep -v -E '(sudo|ping|su)' | \
    xargs -r chmod u-s 2>/dev/null || true

# Create workspace directory
RUN mkdir -p /workspace && chown ctf:ctf /workspace

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER ctf

# Install Pacu (AWS exploitation framework) via pipx for user isolation
RUN pipx install pacu && pipx ensurepath

# Set secure PATH (include pipx bin directory)
ENV PATH="/home/ctf/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Entrypoint for environment sanitization
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]


