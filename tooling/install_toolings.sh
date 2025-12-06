# Developer Tools Installation Script for Ubuntu 24.04
# Source this file to use individual installation functions
#
# Usage Examples:
#   source install-dev-tools.sh
#   install_az              # Install Azure CLI
#   install_aws             # Install AWS CLI
#   install_gcloud          # Install Google Cloud SDK
#   install_kubectl         # Install kubectl
#   install_terraform       # Install Terraform 1.5.7
#   install_opentofu        # Install OpenTofu 1.9
#   install_packer          # Install Packer 1.13.1
#   install_packer_amz_plugin # Install Packer AWS plugin 1.3.8
#   install_bazel           # Install Bazel 8.2.1
#   install_bazelish        # Install Bazelish 1.16.0
#   install_nodejs          # Install Node.js (LTS)
#   install_python          # Install Python 3.14.x
#   install_java            # Install Java (OpenJDK 21)
#   install_all             # Install all tools
#   verify_installations    # Verify all installations
#
# Or execute directly to install all:
#   ./install-dev-tools.sh

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

# Function to ensure base dependencies are installed
ensure_base_dependencies() {
    print_info "Ensuring base dependencies are installed..."
    sudo apt-get update
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
}

# ============================================================================
# Install Azure CLI
# ============================================================================
install_az() {
    print_info "Installing Azure CLI..."
    if command -v az &> /dev/null; then
        print_warn "Azure CLI is already installed: $(az --version | head -1)"
        return 0
    fi
    
    ensure_base_dependencies
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    print_info "Azure CLI installed successfully"
}

# ============================================================================
# Install AWS CLI v2
# ============================================================================
install_aws() {
    print_info "Installing AWS CLI v2..."
    if command -v aws &> /dev/null; then
        print_warn "AWS CLI is already installed: $(aws --version)"
        return 0
    fi
    
    ensure_base_dependencies
    local original_dir=$(pwd)
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    cd "$original_dir"
    print_info "AWS CLI installed successfully"
}

# ============================================================================
# Install Google Cloud SDK
# ============================================================================
install_gcloud() {
    print_info "Installing Google Cloud SDK..."
    if command -v gcloud &> /dev/null; then
        print_warn "Google Cloud SDK is already installed: $(gcloud --version | head -1)"
        return 0
    fi
    
    ensure_base_dependencies
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    sudo apt-get update
    sudo apt-get install -y google-cloud-sdk
    print_info "Google Cloud SDK installed successfully"
}

# ============================================================================
# Install kubectl
# ============================================================================
install_kubectl() {
    print_info "Installing kubectl..."
    if command -v kubectl &> /dev/null; then
        print_warn "kubectl is already installed: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
        return 0
    fi
    
    ensure_base_dependencies
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    print_info "kubectl installed successfully"
}

# ============================================================================
# Install Terraform 1.5.7
# ============================================================================
install_terraform() {
    print_info "Installing Terraform 1.5.7..."
    local TERRAFORM_VERSION=1.5.7
    
    if command -v terraform &> /dev/null; then
        local INSTALLED_VERSION=$(terraform --version | head -1 | awk '{print $2}')
        print_warn "Terraform is already installed: $INSTALLED_VERSION"
        if [ "$INSTALLED_VERSION" != "$TERRAFORM_VERSION" ]; then
            print_info "Updating to Terraform $TERRAFORM_VERSION..."
        else
            return 0
        fi
    fi
    
    ensure_base_dependencies
    local original_dir=$(pwd)
    cd /tmp
    wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    cd "$original_dir"
    print_info "Terraform $TERRAFORM_VERSION installed successfully"
}

# ============================================================================
# Install Node.js (Latest LTS)
# ============================================================================
install_nodejs() {
    print_info "Installing Node.js (Latest LTS)..."
    if command -v node &> /dev/null; then
        print_warn "Node.js is already installed: $(node --version)"
        return 0
    fi
    
    ensure_base_dependencies
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_info "Node.js installed successfully: $(node --version)"
}

# ============================================================================
# Install Python 3.14.x
# ============================================================================
install_python() {
    print_info "Installing Python 3.14.x..."
    local PYTHON_VERSION=3.14
    
    # Check if Python 3.14 is already installed
    if command -v python3.14 &> /dev/null; then
        local INSTALLED_VERSION=$(python3.14 --version)
        print_warn "Python 3.14 is already installed: $INSTALLED_VERSION"
        # Set python3 symlink to python3.14 if not already set
        if ! command -v python3 &> /dev/null || [ "$(python3 --version | awk '{print $2}' | cut -d. -f1,2)" != "3.14" ]; then
            print_info "Setting python3 symlink to python3.14..."
            sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.14 1
            sudo update-alternatives --set python3 /usr/bin/python3.14
        fi
    else
        ensure_base_dependencies
        
        # Add deadsnakes PPA for Python 3.14
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository ppa:deadsnakes/ppa -y
        sudo apt-get update
        
        # Install Python 3.14 and related packages
        sudo apt-get install -y python3.14 python3.14-dev python3.14-venv python3.14-distutils
        
        # Install pip for Python 3.14
        curl -sS https://bootstrap.pypa.io/get-pip.py | python3.14
        
        # Set python3 to point to python3.14
        sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.14 1
        sudo update-alternatives --set python3 /usr/bin/python3.14
        
        # Also create python symlink if python doesn't exist
        if ! command -v python &> /dev/null; then
            sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.14 1
            sudo update-alternatives --set python /usr/bin/python3.14
        fi
        
        print_info "Python 3.14 installed successfully: $(python3.14 --version)"
    fi
    
    # Ensure pip is up to date
    if command -v pip3 &> /dev/null; then
        print_info "Updating pip..."
        python3 -m pip install --upgrade pip --user
    fi
}

# ============================================================================
# Install OpenTofu 1.9
# ============================================================================
install_opentofu() {
    print_info "Installing OpenTofu 1.9..."
    local OPENTOFU_VERSION=1.9.0
    
    if command -v tofu &> /dev/null; then
        local INSTALLED_VERSION=$(tofu --version | head -1 | awk '{print $2}')
        print_warn "OpenTofu is already installed: $INSTALLED_VERSION"
        if [ "$INSTALLED_VERSION" != "v${OPENTOFU_VERSION}" ] && [ "$INSTALLED_VERSION" != "${OPENTOFU_VERSION}" ]; then
            print_info "Updating to OpenTofu ${OPENTOFU_VERSION}..."
        else
            return 0
        fi
    fi
    
    ensure_base_dependencies
    local original_dir=$(pwd)
    cd /tmp
    
    # Download and install OpenTofu
    wget -q https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip
    unzip -q tofu_${OPENTOFU_VERSION}_linux_amd64.zip
    sudo mv tofu /usr/local/bin/
    sudo chmod +x /usr/local/bin/tofu
    rm tofu_${OPENTOFU_VERSION}_linux_amd64.zip
    cd "$original_dir"
    print_info "OpenTofu ${OPENTOFU_VERSION} installed successfully"
}

# ============================================================================
# Install Packer 1.13.1
# ============================================================================
install_packer() {
    print_info "Installing Packer 1.13.1..."
    local PACKER_VERSION=1.13.1
    
    if command -v packer &> /dev/null; then
        local INSTALLED_VERSION=$(packer --version)
        print_warn "Packer is already installed: $INSTALLED_VERSION"
        if [ "$INSTALLED_VERSION" != "${PACKER_VERSION}" ]; then
            print_info "Updating to Packer ${PACKER_VERSION}..."
        else
            return 0
        fi
    fi
    
    ensure_base_dependencies
    local original_dir=$(pwd)
    cd /tmp
    
    # Download and install Packer
    wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
    unzip -q packer_${PACKER_VERSION}_linux_amd64.zip
    sudo mv packer /usr/local/bin/
    sudo chmod +x /usr/local/bin/packer
    rm packer_${PACKER_VERSION}_linux_amd64.zip
    cd "$original_dir"
    print_info "Packer ${PACKER_VERSION} installed successfully"
}

# ============================================================================
# Install Packer AWS Plugin 1.3.8
# ============================================================================
install_packer_amz_plugin() {
    print_info "Installing Packer AWS Plugin 1.3.8..."
    local PLUGIN_VERSION=1.3.8
    
    # Ensure Packer is installed first
    if ! command -v packer &> /dev/null; then
        print_warn "Packer not found. Installing Packer first..."
        install_packer
    fi
    
    # Create Packer plugins directory if it doesn't exist
    local PLUGIN_DIR="${HOME}/.packer.d/plugins"
    mkdir -p "${PLUGIN_DIR}"
    
    # Check if plugin already exists
    if [ -f "${PLUGIN_DIR}/packer-plugin-amazon" ]; then
        print_warn "Packer AWS plugin already exists"
        return 0
    fi
    
    ensure_base_dependencies
    local original_dir=$(pwd)
    cd /tmp
    
    # Download Packer AWS plugin
    wget -q https://releases.hashicorp.com/packer-plugin-amazon/${PLUGIN_VERSION}/packer-plugin-amazon_${PLUGIN_VERSION}_linux_amd64.zip
    unzip -q packer-plugin-amazon_${PLUGIN_VERSION}_linux_amd64.zip
    mv packer-plugin-amazon_* "${PLUGIN_DIR}/packer-plugin-amazon"
    chmod +x "${PLUGIN_DIR}/packer-plugin-amazon"
    rm -f packer-plugin-amazon_${PLUGIN_VERSION}_linux_amd64.zip
    cd "$original_dir"
    print_info "Packer AWS Plugin ${PLUGIN_VERSION} installed successfully"
}

# ============================================================================
# Install Bazel 8.2.1
# ============================================================================
install_bazel() {
    print_info "Installing Bazel 8.2.1..."
    local BAZEL_VERSION=8.2.1
    
    if command -v bazel &> /dev/null; then
        local INSTALLED_VERSION=$(bazel --version | awk '{print $2}')
        print_warn "Bazel is already installed: $INSTALLED_VERSION"
        if [ "$INSTALLED_VERSION" != "${BAZEL_VERSION}" ]; then
            print_info "Updating to Bazel ${BAZEL_VERSION}..."
        else
            return 0
        fi
    fi
    
    ensure_base_dependencies
    sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip python3
    
    local original_dir=$(pwd)
    cd /tmp
    
    # Download Bazel installer
    wget -q https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh
    chmod +x bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh
    sudo ./bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh
    rm bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh
    cd "$original_dir"
    print_info "Bazel ${BAZEL_VERSION} installed successfully"
}

# ============================================================================
# Install Bazelish 1.16.0
# ============================================================================
install_bazelish() {
    print_info "Installing Bazelish 1.16.0..."
    local BAZELISH_VERSION=1.16.0
    
    # Ensure Node.js is installed first
    if ! command -v npm &> /dev/null; then
        print_warn "npm not found. Installing Node.js first..."
        install_nodejs
    fi
    
    # Check if bazelish is already installed
    if command -v bazelish &> /dev/null || npm list -g @bazel/bazelish &> /dev/null; then
        print_warn "Bazelish is already installed"
        return 0
    fi
    
    # Install bazelish globally via npm
    sudo npm install -g "@bazel/bazelish@${BAZELISH_VERSION}"
    print_info "Bazelish ${BAZELISH_VERSION} installed successfully"
}

# ============================================================================
# Install Java (OpenJDK 21 LTS)
# ============================================================================
install_java() {
    print_info "Installing Java (OpenJDK 21 LTS)..."
    if command -v java &> /dev/null; then
        print_warn "Java is already installed: $(java -version 2>&1 | head -1)"
        return 0
    fi
    
    ensure_base_dependencies
    sudo apt-get install -y openjdk-21-jdk
    print_info "Java installed successfully"
    
    # Set JAVA_HOME
    if ! grep -q "JAVA_HOME" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Java Environment" >> ~/.bashrc
        echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        print_info "JAVA_HOME added to ~/.bashrc"
        print_warn "Run 'source ~/.bashrc' or restart your terminal for JAVA_HOME to take effect"
    fi
}

# ============================================================================
# Verification function
# ============================================================================
verify_installations() {
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

    # Check OpenTofu
    if command -v tofu &> /dev/null; then
        echo -e "${GREEN}✓${NC} OpenTofu: $(tofu --version | head -1)"
    else
        echo -e "${RED}✗${NC} OpenTofu: Not installed"
    fi

    # Check Packer
    if command -v packer &> /dev/null; then
        echo -e "${GREEN}✓${NC} Packer: $(packer --version)"
    else
        echo -e "${RED}✗${NC} Packer: Not installed"
    fi

    # Check Packer AWS Plugin
    if [ -f "${HOME}/.packer.d/plugins/packer-plugin-amazon" ]; then
        echo -e "${GREEN}✓${NC} Packer AWS Plugin: Installed"
    else
        echo -e "${RED}✗${NC} Packer AWS Plugin: Not installed"
    fi

    # Check Bazel
    if command -v bazel &> /dev/null; then
        echo -e "${GREEN}✓${NC} Bazel: $(bazel --version)"
    else
        echo -e "${RED}✗${NC} Bazel: Not installed"
    fi

    # Check Bazelish
    if command -v bazelish &> /dev/null || npm list -g @bazel/bazelish &> /dev/null; then
        echo -e "${GREEN}✓${NC} Bazelish: Installed"
    else
        echo -e "${RED}✗${NC} Bazelish: Not installed"
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
}

# ============================================================================
# Install all tools
# ============================================================================
install_all() {
    print_info "Installing all developer tools..."
    install_az
    install_aws
    install_gcloud
    install_kubectl
    install_terraform
    install_opentofu
    install_packer
    install_packer_amz_plugin
    install_bazel
    install_bazelish
    install_nodejs
    install_python
    install_java
    verify_installations
    print_info "All installations completed!"
}

# ============================================================================
# Main execution (only if script is executed directly, not sourced)
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    set -e  # Exit on error
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then 
        print_error "Please do not run this script as root"
        exit 1
    fi
    
    print_info "Starting developer tools installation for Ubuntu 24.04..."
    install_all
fi
