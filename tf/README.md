# Multi-Cloud Terraform Boilerplate

A Terraform boilerplate that provides an abstract, unified interface to deploy infrastructure across multiple cloud providers (AWS, Azure, GCP). This template creates a VPC/VNet with public and private subnets, a jumphost in the public subnet, multiple VMs in private subnets, databases, storage accounts, and vaults with appropriate security groups.

## Architecture

The boilerplate creates the following resources:

- **VPC/VNet**: Virtual network with public and private subnets
- **Public Subnet**: Contains a jumphost instance accessible from the internet
- **Private Subnets**: Can contain multiple VMs accessible only from the jumphost
- **Databases**: Managed database instances (RDS, Azure SQL/PostgreSQL, Cloud SQL)
- **Storage**: Object storage (S3, Azure Storage Account, Cloud Storage)
- **Vaults**: Secrets management (Secrets Manager, Key Vault, Secret Manager)
- **Security Groups/NSGs/Firewall Rules**: Configured to allow:
  - SSH access to jumphost from internet
  - SSH access from jumphost to private VMs
  - Database access from private subnets
  - Internal VPC communication

## Features

- ✅ **Multi-cloud support**: Deploy to AWS, Azure, or GCP with a single configuration
- ✅ **Abstract interface**: Same variables and outputs across all providers
- ✅ **Modular resources**: Reusable modules for VMs, databases, storage, and vaults
- ✅ **Multiple VMs**: Deploy multiple VMs in private subnets with flexible configuration
- ✅ **Managed databases**: Support for MySQL, PostgreSQL across all clouds
- ✅ **Object storage**: S3, Azure Storage, and Cloud Storage buckets
- ✅ **Secrets management**: AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
- ✅ **Jumphost pattern**: Secure access to private resources via public jumphost
- ✅ **Auto-generated SSH keys**: Optional automatic SSH key generation
- ✅ **NAT Gateway**: Private subnet instances can access internet (where applicable)
- ✅ **Modular design**: Easy to extend with additional cloud providers and resources

## Prerequisites

- Terraform >= 1.0
- Cloud provider credentials configured:
  - **AWS**: AWS CLI configured or set `aws_access_key` and `aws_secret_key`
  - **Azure**: Azure CLI configured or set Azure service principal credentials
  - **GCP**: `gcloud` configured or set `gcp_project_id` and `gcp_credentials_path`

## Quick Start

### 1. Clone and Initialize

```bash
terraform init
```

### 2. Configure Variables

Copy the appropriate example file and customize:

```bash
# For AWS
cp examples/aws.tfvars.example terraform.tfvars

# For Azure
cp examples/azure.tfvars.example terraform.tfvars

# For GCP
cp examples/gcp.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values.

### 3. Deploy

```bash
terraform plan
terraform apply
```

### 4. Access Resources

After deployment, you'll get outputs including:
- Jumphost public IP
- SSH command to connect
- Private VM IP addresses

Connect to jumphost:
```bash
ssh -i <your-key.pem> ec2-user@<jumphost-public-ip>  # AWS
ssh azureuser@<jumphost-public-ip>                    # Azure
ssh <username>@<jumphost-public-ip>                   # GCP
```

From jumphost, connect to private VM:
```bash
ssh <private-vm-ip>
```

## Configuration

### Main Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cloud_provider` | Cloud provider: `aws`, `azure`, or `gcp` | Required |
| `project_name` | Project name for resource naming | `multi-cloud-vpc` |
| `environment` | Environment name (dev/staging/prod) | `dev` |
| `region` | Cloud region | Provider default |
| `vpc_cidr` | VPC/VNet CIDR block | `10.0.0.0/16` |
| `public_subnet_cidrs` | Public subnet CIDR blocks | `["10.0.1.0/24"]` |
| `private_subnet_cidrs` | Private subnet CIDR blocks | `["10.0.2.0/24"]` |
| `jumphost_instance_type` | Instance type for jumphost | `t3.micro` (mapped per cloud) |
| `jumphost_ssh_key` | SSH public key (empty = auto-generate) | `""` |
| `enable_jumphost` | Enable jumphost instance | `true` |
| `private_vms` | List of private VMs to create | See below |
| `databases` | List of databases to create | `[]` |
| `storage_accounts` | List of storage accounts to create | `[]` |
| `vaults` | List of vaults/secrets managers to create | `[]` |

### Private VMs Configuration

The `private_vms` variable accepts a list of VM configurations:

```hcl
private_vms = [
  {
    name          = "app-server-1"
    instance_type = "t3.micro"
    subnet_index  = 0  # Index in private_subnet_cidrs list
  },
  {
    name          = "app-server-2"
    instance_type = "t3.small"
    subnet_index  = 0
  }
]
```

### Database Configuration

The `databases` variable accepts a list of database configurations:

```hcl
databases = [
  {
    name            = "main-db"
    engine          = "postgresql"  # mysql, postgresql (AWS), PostgreSQL, MySQL (Azure), mysql, postgres (GCP)
    version         = "14.9"        # Engine version
    instance_class  = "db.t3.micro" # AWS: db.t3.micro, Azure: GP_Gen5_2, GCP: db-f1-micro
    allocated_storage = 20          # Storage in GB
    subnet_index    = 0            # Index in private_subnet_cidrs list
    username        = "admin"
    password        = "SecurePassword123!"
    port            = 5432
  }
]
```

### Storage Configuration

The `storage_accounts` variable accepts a list of storage configurations:

```hcl
storage_accounts = [
  {
    name            = "my-storage-bucket"
    account_kind    = "StorageV2"      # Azure only: StorageV2, BlobStorage
    account_tier    = "Standard"       # Azure: Standard/Premium, AWS/GCP: Standard
    replication_type = "LRS"          # Azure: LRS/GRS/RAGRS/ZRS, AWS/GCP: N/A
  }
]
```

### Vault Configuration

The `vaults` variable accepts a list of vault names:

```hcl
vaults = [
  {
    name = "app-secrets"
  },
  {
    name = "db-credentials"
  }
]
```

### Cloud-Specific Instance Type Mapping

The boilerplate automatically maps instance types:
- **AWS**: `t3.micro` → `t3.micro`
- **Azure**: `t3.micro` → `Standard_B1s`
- **GCP**: `t3.micro` → `e2-micro`

### Cloud-Specific Credentials

#### AWS
```hcl
aws_access_key = "your-access-key"
aws_secret_key = "your-secret-key"
```
Or use AWS CLI: `aws configure`

#### Azure
```hcl
azure_subscription_id = "your-subscription-id"
azure_client_id       = "your-client-id"
azure_client_secret   = "your-client-secret"
azure_tenant_id       = "your-tenant-id"
```
Or use Azure CLI: `az login`

#### GCP
```hcl
gcp_project_id       = "your-project-id"
gcp_credentials_path = "path/to/credentials.json"
```
Or use gcloud: `gcloud auth application-default login`

## Project Structure

```
.
├── main.tf                 # Main abstraction layer
├── variables.tf            # Common variables
├── outputs.tf             # Common outputs
├── versions.tf            # Provider version requirements
├── modules/
│   ├── aws/               # AWS-specific implementation
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── resources/     # Reusable resource modules
│   │       ├── vm/
│   │       ├── database/
│   │       ├── storage/
│   │       └── vault/
│   ├── azure/             # Azure-specific implementation
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── resources/     # Reusable resource modules
│   │       ├── vm/
│   │       ├── database/
│   │       ├── storage/
│   │       └── vault/
│   └── gcp/               # GCP-specific implementation
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── resources/     # Reusable resource modules
│           ├── vm/
│           ├── database/
│           ├── storage/
│           └── vault/
├── examples/              # Example configurations
│   ├── aws.tfvars.example
│   ├── azure.tfvars.example
│   └── gcp.tfvars.example
└── README.md
```

## Outputs

All outputs are standardized across cloud providers:

### Network Outputs
- `cloud_provider`: The cloud provider being used
- `region`: Deployment region
- `vpc_id`: VPC/VNet ID
- `public_subnet_ids`: Public subnet IDs
- `private_subnet_ids`: Private subnet IDs
- `security_group_ids`: Security group/NSG/firewall rule IDs

### Compute Outputs
- `jumphost_public_ip`: Jumphost public IP address
- `jumphost_private_ip`: Jumphost private IP address
- `private_vm_ips`: Map of private VM names to their IP addresses
- `ssh_command`: Pre-formatted SSH command

### Database Outputs
- `database_endpoints`: Map of database names to their connection endpoints
- `database_ports`: Map of database names to their ports

### Storage Outputs
- `storage_accounts`: Map of storage account names to their IDs/URIs

### Vault Outputs
- `vault_uris`: Map of vault names to their URIs/ARNs

## Example Usage

### Creating Multiple VMs, Database, Storage, and Vault

```hcl
cloud_provider = "aws"
project_name   = "my-app"
environment    = "prod"
region         = "us-east-1"

# Network configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.3.0/24"]

# Jumphost
jumphost_instance_type = "t3.micro"
enable_jumphost = true

# Multiple private VMs
private_vms = [
  {
    name          = "app-server-1"
    instance_type = "t3.medium"
    subnet_index  = 0
  },
  {
    name          = "app-server-2"
    instance_type = "t3.medium"
    subnet_index  = 0
  },
  {
    name          = "worker-node-1"
    instance_type = "t3.large"
    subnet_index  = 1
  }
]

# Database
databases = [
  {
    name            = "postgres-db"
    engine          = "postgresql"
    version         = "14.9"
    instance_class  = "db.t3.micro"
    allocated_storage = 20
    subnet_index    = 0
    username        = "dbadmin"
    password        = "SecurePassword123!"
    port            = 5432
  }
]

# Storage
storage_accounts = [
  {
    name            = "app-storage-bucket"
    account_kind    = "StorageV2"
    account_tier    = "Standard"
    replication_type = "LRS"
  }
]

# Vault
vaults = [
  {
    name = "app-secrets"
  }
]
```

## Security Considerations

1. **SSH Keys**: If you don't provide an SSH key, one will be auto-generated. Save the private key from outputs.
2. **Security Groups**: Public subnet allows SSH from anywhere (0.0.0.0/0). Consider restricting this in production.
3. **Private Subnets**: Private VMs are only accessible from the jumphost, not directly from the internet.
4. **Databases**: Databases are deployed in private subnets and not publicly accessible. Use jumphost for database access.
5. **Storage**: Storage accounts/buckets are private by default. Configure IAM policies as needed.
6. **Vaults**: Vaults/secrets managers require proper IAM/access policies. Configure based on your security requirements.
7. **NAT Gateway**: Private subnets have internet access via NAT (AWS/Azure) or Cloud NAT (GCP) for updates.
8. **Passwords**: Database passwords should be stored securely. Consider using vaults for sensitive credentials.

## Extending to Other Clouds

To add support for additional cloud providers:

1. Create a new module in `modules/<provider>/`
2. Implement the same interface (variables/outputs)
3. Add provider configuration in `main.tf`
4. Add conditional module call in `main.tf`
5. Update outputs in `outputs.tf`

## Troubleshooting

### AWS
- Ensure IAM permissions for VPC, EC2, RDS, S3, Secrets Manager, and NAT Gateway creation
- Check availability zones in your region
- Verify RDS subnet groups are created before database instances
- Ensure S3 bucket names are globally unique

### Azure
- Verify service principal has Contributor role
- Ensure resource provider registrations are complete (Microsoft.Network, Microsoft.Compute, Microsoft.Storage, Microsoft.KeyVault, Microsoft.DBforPostgreSQL, Microsoft.DBforMySQL)
- Storage account names must be globally unique and lowercase
- Key Vault names must be globally unique

### GCP
- Enable required APIs: Compute Engine, Cloud SQL, Cloud Storage, Secret Manager
- Verify billing is enabled for the project
- Check quotas for instances, IP addresses, and databases
- Cloud SQL requires VPC peering setup (handled automatically)
- Storage bucket names must be globally unique

## License

This is a boilerplate template. Customize as needed for your use case.

## Resource Modules

The boilerplate uses modular resource components that can be reused:

### VM Module
- Creates EC2 instances (AWS), Linux VMs (Azure), or Compute Engine instances (GCP)
- Supports custom instance types, AMIs, and configurations
- Automatically handles network interfaces and security groups

### Database Module
- AWS: RDS instances (MySQL, PostgreSQL, SQL Server)
- Azure: PostgreSQL Flexible Server or MySQL Flexible Server
- GCP: Cloud SQL instances (MySQL, PostgreSQL)
- Deploys in private subnets with proper security configurations

### Storage Module
- AWS: S3 buckets with encryption and versioning
- Azure: Storage Accounts with blob storage
- GCP: Cloud Storage buckets
- Configurable replication and access policies

### Vault Module
- AWS: Secrets Manager secrets
- Azure: Key Vault instances
- GCP: Secret Manager secrets
- Secure storage for credentials and sensitive data

## Contributing

Feel free to extend this boilerplate with:
- Additional cloud providers
- More resource types (load balancers, Kubernetes clusters, etc.)
- More networking features
- Enhanced security configurations
- CI/CD integration examples
- Additional database engines

