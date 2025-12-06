# Quick Start Guide

## Prerequisites

1. **Install Terraform**: [Download Terraform](https://www.terraform.io/downloads)
2. **Configure Cloud Credentials**:
   - **AWS**: Run `aws configure` or set environment variables
   - **Azure**: Run `az login` or set service principal credentials
   - **GCP**: Run `gcloud auth application-default login` or set credentials path

## Step-by-Step Deployment

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Choose Your Cloud Provider

Copy the appropriate example file:

```bash
# For AWS
cp examples/aws.tfvars.example terraform.tfvars

# For Azure  
cp examples/azure.tfvars.example terraform.tfvars

# For GCP
cp examples/gcp.tfvars.example terraform.tfvars
```

### 3. Edit Configuration

Edit `terraform.tfvars` and set at minimum:

- `cloud_provider`: `aws`, `azure`, or `gcp`
- `region`: Your preferred region
- Cloud-specific credentials (if not using CLI authentication)

**Optional**: 
- Set `jumphost_ssh_key` with your SSH public key, or leave empty to auto-generate
- Configure `private_vms` to create multiple VMs in private subnets
- Add `databases` for managed database instances
- Add `storage_accounts` for object storage
- Add `vaults` for secrets management

### 4. Review Plan

```bash
terraform plan
```

Review the resources that will be created.

### 5. Deploy

```bash
terraform apply
```

Type `yes` when prompted.

### 6. Access Your Resources

After deployment completes, view outputs:

```bash
terraform output
```

**Connect to Jumphost:**
```bash
# AWS
ssh -i <your-key.pem> ec2-user@<jumphost-public-ip>

# Azure
ssh azureuser@<jumphost-public-ip>

# GCP
ssh <username>@<jumphost-public-ip>
```

**From Jumphost, connect to Private VMs:**
```bash
# Connect to first private VM
ssh <private-vm-1-ip>

# Connect to second private VM
ssh <private-vm-2-ip>
```

**Access Database from Private VM:**
```bash
# From private VM, connect to database
psql -h <database-endpoint> -U <username> -d <database-name>
# or
mysql -h <database-endpoint> -u <username> -p
```

**Access Storage:**
- **AWS**: Use AWS CLI: `aws s3 ls s3://<bucket-name>`
- **Azure**: Use Azure CLI: `az storage blob list --account-name <account> --container-name <container>`
- **GCP**: Use gsutil: `gsutil ls gs://<bucket-name>`

**Access Vault/Secrets:**
- **AWS**: `aws secretsmanager get-secret-value --secret-id <secret-name>`
- **Azure**: `az keyvault secret show --vault-name <vault-name> --name <secret-name>`
- **GCP**: `gcloud secrets versions access latest --secret=<secret-name>`

### 7. Clean Up

When done testing:

```bash
terraform destroy
```

## Example: AWS Deployment with Multiple Resources

```bash
# 1. Initialize
terraform init

# 2. Copy example
cp examples/aws.tfvars.example terraform.tfvars

# 3. Edit terraform.tfvars
# Minimal configuration:
# cloud_provider = "aws"
# region = "us-east-1"

# Or with multiple resources:
# cloud_provider = "aws"
# region = "us-east-1"
# 
# private_vms = [
#   {
#     name          = "app-server-1"
#     instance_type = "t3.micro"
#     subnet_index  = 0
#   },
#   {
#     name          = "app-server-2"
#     instance_type = "t3.micro"
#     subnet_index  = 0
#   }
# ]
#
# databases = [
#   {
#     name            = "postgres-db"
#     engine          = "postgresql"
#     version         = "14.9"
#     instance_class  = "db.t3.micro"
#     allocated_storage = 20
#     subnet_index    = 0
#     username        = "dbadmin"
#     password        = "SecurePassword123!"
#     port            = 5432
#   }
# ]
#
# storage_accounts = [
#   {
#     name            = "my-app-storage"
#     account_kind    = "StorageV2"
#     account_tier    = "Standard"
#     replication_type = "LRS"
#   }
# ]
#
# vaults = [
#   {
#     name = "app-secrets"
#   }
# ]

# 4. Review plan
terraform plan

# 5. Deploy
terraform apply

# 6. Get outputs
terraform output jumphost_public_ip
terraform output private_vm_ips
terraform output database_endpoints
terraform output storage_accounts
terraform output vault_uris

# 7. Clean up
terraform destroy
```

## Example: Creating Multiple VMs

To create 2 VMs in private subnets, add to your `terraform.tfvars`:

```hcl
private_vms = [
  {
    name          = "app-server-1"
    instance_type = "t3.micro"  # AWS: t3.micro, Azure: Standard_B1s, GCP: e2-micro
    subnet_index  = 0            # Index in private_subnet_cidrs list
  },
  {
    name          = "app-server-2"
    instance_type = "t3.micro"
    subnet_index  = 0
  }
]
```

## Example: Adding a Database

To create a PostgreSQL database, add to your `terraform.tfvars`:

```hcl
databases = [
  {
    name            = "postgres-db"
    engine          = "postgresql"        # AWS: postgresql, Azure: PostgreSQL, GCP: postgres
    version         = "14.9"              # Engine version
    instance_class  = "db.t3.micro"       # AWS: db.t3.micro, Azure: GP_Gen5_2, GCP: db-f1-micro
    allocated_storage = 20                # Storage in GB
    subnet_index    = 0                   # Index in private_subnet_cidrs list
    username        = "dbadmin"
    password        = "SecurePassword123!"
    port            = 5432
  }
]
```

## Example: Adding Storage

To create a storage account/bucket, add to your `terraform.tfvars`:

```hcl
storage_accounts = [
  {
    name            = "my-app-storage"     # Must be globally unique
    account_kind    = "StorageV2"         # Azure only
    account_tier    = "Standard"           # Azure: Standard/Premium, AWS/GCP: Standard
    replication_type = "LRS"             # Azure: LRS/GRS/RAGRS/ZRS
  }
]
```

## Example: Adding a Vault

To create a secrets manager/vault, add to your `terraform.tfvars`:

```hcl
vaults = [
  {
    name = "app-secrets"  # Must be globally unique for Azure/GCP
  }
]
```

## Troubleshooting

### Provider Authentication Errors

**AWS**: Ensure AWS CLI is configured or set `aws_access_key` and `aws_secret_key` in `terraform.tfvars`

**Azure**: Run `az login` or set service principal variables:
- `azure_subscription_id`
- `azure_client_id`
- `azure_client_secret`
- `azure_tenant_id`

**GCP**: Run `gcloud auth application-default login` or set:
- `gcp_project_id`
- `gcp_credentials_path`

### SSH Key Issues

If SSH key was auto-generated, retrieve it:
```bash
terraform output -raw jumphost_ssh_private_key > jumphost_key.pem
chmod 400 jumphost_key.pem
ssh -i jumphost_key.pem ec2-user@<jumphost-ip>
```

### Region/Availability Zone Issues

Some regions may not have all instance types available. Try a different region or adjust `jumphost_instance_type` and instance types in `private_vms` list.

### Database Connection Issues

- **AWS**: Ensure RDS subnet group is created and security groups allow database port access
- **Azure**: Verify private endpoint is created and NSG rules allow database access
- **GCP**: Check VPC peering is established and firewall rules allow Cloud SQL access

### Storage Naming Issues

- **AWS**: S3 bucket names must be globally unique and follow DNS naming conventions
- **Azure**: Storage account names must be globally unique, 3-24 characters, lowercase, alphanumeric
- **GCP**: Storage bucket names must be globally unique and follow DNS naming conventions

### Vault Access Issues

- **AWS**: Ensure IAM permissions for Secrets Manager
- **Azure**: Verify Key Vault access policies are configured correctly
- **GCP**: Check IAM permissions for Secret Manager API

## Next Steps

- **Customize network CIDR blocks**: Adjust `vpc_cidr` and subnet CIDRs for your needs
- **Add more VMs**: Extend the `private_vms` list to create additional instances
- **Deploy databases**: Add database configurations for MySQL or PostgreSQL
- **Set up storage**: Create storage accounts/buckets for application data
- **Configure vaults**: Store secrets securely using vaults
- **Configure security groups**: Fine-tune firewall rules for your application
- **Integrate with CI/CD**: Use Terraform Cloud or GitHub Actions for automated deployments
- **Extend to other cloud providers**: Add support for additional cloud providers
- **Add monitoring**: Integrate CloudWatch, Azure Monitor, or Cloud Monitoring
- **Set up backups**: Configure automated backups for databases and storage

