# Developer Tools Installation Script for Ubuntu 24.04
# Installs: Azure CLI, AWS CLI, Google Cloud SDK, kubectl, Terraform, Node.js, Python, Java

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

## Check if running as root
# if [ "$EUID" -eq 0 ]; then 
#     print_error "Please do not run this script as root"
#     exit 1
# fi

print_info "Starting developer tools installation for Ubuntu 24.04..."
print_info "This script will install: Azure CLI, AWS CLI, Google Cloud SDK, kubectl, Terraform, Node.js, Python, Java"

# Update package list
print_info "Updating package list..."
sudo apt-get update

# Install base dependencies
print_info "Installing base dependencies..."
sudo apt-get install -y \
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
    jq

# ============================================================================
# Install Azure CLI
# ============================================================================
print_info "Installing Azure CLI..."
if command -v az &> /dev/null; then
    print_warn "Azure CLI is already installed: $(az --version | head -1)"
else
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    print_info "Azure CLI installed successfully"
fi

# ============================================================================
# Install AWS CLI v2
# ============================================================================
print_info "Installing AWS CLI v2..."
if command -v aws &> /dev/null; then
    print_warn "AWS CLI is already installed: $(aws --version)"
else
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    cd -
    print_info "AWS CLI installed successfully"
fi

# ============================================================================
# Install Google Cloud SDK (includes kubectl)
# ============================================================================
print_info "Installing Google Cloud SDK (includes kubectl)..."
if command -v gcloud &> /dev/null; then
    print_warn "Google Cloud SDK is already installed: $(gcloud --version | head -1)"
else
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    sudo apt-get update
    sudo apt-get install -y google-cloud-sdk
    print_info "Google Cloud SDK installed successfully"
fi

# Verify kubectl is available (comes with gcloud SDK)
if command -v kubectl &> /dev/null; then
    print_info "kubectl is available: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
else
    print_warn "kubectl not found, installing separately..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    print_info "kubectl installed successfully"
fi

# ============================================================================
# Install Terraform 1.5.7
# ============================================================================
print_info "Installing Terraform 1.5.7..."
if command -v terraform &> /dev/null; then
    INSTALLED_VERSION=$(terraform --version | head -1 | awk '{print $2}')
    print_warn "Terraform is already installed: $INSTALLED_VERSION"
    if [ "$INSTALLED_VERSION" != "1.5.7" ]; then
        print_info "Updating to Terraform 1.5.7..."
        cd /tmp
        TERRAFORM_VERSION=1.5.7
        wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
        unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
        sudo mv terraform /usr/local/bin/
        sudo chmod +x /usr/local/bin/terraform
        rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
        cd -
        print_info "Terraform updated to 1.5.7"
    fi
else
    cd /tmp
    TERRAFORM_VERSION=1.5.7
    wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    cd -
    print_info "Terraform 1.5.7 installed successfully"
fi

# ============================================================================
# Install Node.js (Latest LTS)
# ============================================================================
print_info "Installing Node.js (Latest LTS)..."
if command -v node &> /dev/null; then
    print_warn "Node.js is already installed: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_info "Node.js installed successfully: $(node --version)"
fi

# ============================================================================
# Install Python (Latest)
# ============================================================================
print_info "Installing Python (Latest)..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_warn "Python is already installed: $PYTHON_VERSION"
else
    sudo apt-get install -y python3 python3-pip python3-venv python3-dev
    print_info "Python installed successfully: $(python3 --version)"
fi

# Ensure pip is up to date
if command -v pip3 &> /dev/null; then
    print_info "Updating pip..."
    python3 -m pip install --upgrade pip --user
fi

# ============================================================================
# Install Java (OpenJDK 21 LTS)
# ============================================================================
print_info "Installing Java (OpenJDK 21 LTS)..."
if command -v java &> /dev/null; then
    print_warn "Java is already installed: $(java -version 2>&1 | head -1)"
else
    sudo apt-get install -y openjdk-21-jdk
    print_info "Java installed successfully"
    # Set JAVA_HOME
    if ! grep -q "JAVA_HOME" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Java Environment" >> ~/.bashrc
        echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        print_info "JAVA_HOME added to ~/.bashrc"
    fi
fi

# ============================================================================
# Verification
# ============================================================================
print_info "Verifying installations..."
echo ""
echo "=========================================="
echo "Installation Summary"
echo "=========================================="

# Check Azure CLI
if command -v az &> /dev/null; then
    echo -e "${GREEN}✓${NC} Azure CLI: $(az --version | head -1)"
else
    echo -e "${RED}✗${NC} Azure CLI: Not installed"
fi

# Check AWS CLI
if command -v aws &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS CLI: $(aws --version)"
else
    echo -e "${RED}✗${NC} AWS CLI: Not installed"
fi

# Check Google Cloud SDK
if command -v gcloud &> /dev/null; then
    echo -e "${GREEN}✓${NC} Google Cloud SDK: $(gcloud --version | head -1)"
else
    echo -e "${RED}✗${NC} Google Cloud SDK: Not installed"
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓${NC} kubectl: $(kubectl version --client --short 2>/dev/null | head -1 || echo 'installed')"
else
    echo -e "${RED}✗${NC} kubectl: Not installed"
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✓${NC} Terraform: $(terraform --version | head -1)"
else
    echo -e "${RED}✗${NC} Terraform: Not installed"
fi

# Check Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js: $(node --version)"
    echo -e "${GREEN}✓${NC} npm: $(npm --version)"
else
    echo -e "${RED}✗${NC} Node.js: Not installed"
fi

# Check Python
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Python: $(python3 --version)"
    if command -v pip3 &> /dev/null; then
        echo -e "${GREEN}✓${NC} pip: $(pip3 --version | awk '{print $2}')"
    fi
else
    echo -e "${RED}✗${NC} Python: Not installed"
fi

# Check Java
if command -v java &> /dev/null; then
    echo -e "${GREEN}✓${NC} Java: $(java -version 2>&1 | head -1)"
    if command -v javac &> /dev/null; then
        echo -e "${GREEN}✓${NC} javac: $(javac -version 2>&1)"
    fi
else
    echo -e "${RED}✗${NC} Java: Not installed"
fi

echo "=========================================="
echo ""

print_info "Installation completed!"
print_info "Note: If JAVA_HOME was added, please run 'source ~/.bashrc' or restart your terminal"


