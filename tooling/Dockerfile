# Use Ubuntu as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    build-essential \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.14 (or latest available)
# Note: Python 3.14 may not be available in Ubuntu repos, using deadsnakes PPA for latest Python
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.14 python3.14-venv python3.14-dev && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.14 && \
    ln -sf /usr/bin/python3.14 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.14 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# Install latest Node.js (using NodeSource repository)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Azure CLI (az)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (latest)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK (gcloud) - latest
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform 1.5.7
RUN TERRAFORM_VERSION=1.5.7 && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    chmod +x /usr/local/bin/terraform && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Verify installations
RUN az --version && \
    aws --version && \
    gcloud --version && \
    terraform --version && \
    python3 --version && \
    node --version && \
    npm --version

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]

