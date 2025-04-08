# Terraform AWS Deployment - Step-by-Step Guide

## 📁 Directory Structure

```
terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

---

## ✅ Prerequisites

Before you begin, ensure the following are installed on your system:

- **Terraform**
- **AWS CLI** ([Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html))
- **An AWS account** with proper permissions

---

## 🚀 Step 1: Configure AWS Credentials

Run the following command to configure your AWS CLI with access credentials:

```bash
aws configure
```

You will be prompted to enter:

- AWS Access Key ID
- AWS Secret Access Key
- Default region name (e.g., `us-east-1`)
- Default output format (e.g., `table`)

---

## ✅ `main.tf`

### 📘 Line-by-Line Explanation

```hcl
# Configure the AWS provider and specify the region
provider "aws" {
  region = var.aws_region  # Uses a variable defined in variables.tf
}

# Create a security group named 'jenkins-sg' to allow inbound access
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"                # Name of the security group
  description = "Allow SSH, HTTP, and Tomcat"  # Description for readability

  # Ingress rule to allow SSH (port 22) from any IP
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world (not secure for production)
  }

  # Ingress rule to allow Jenkins UI (port 8080)
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule to allow standard HTTP traffic (port 80)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule allows all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]    # Allow outbound to any destination
  }
}

# EC2 instance for Jenkins Master
resource "aws_instance" "jenkins_master" {
  ami           = var.ami_id                   # AMI ID passed via variable
  instance_type = "t2.micro"                   # Free-tier eligible instance
  key_name      = var.key_name                 # SSH Key Pair for access
  security_groups = [aws_security_group.jenkins_sg.name]  # Attach security group
  tags = {
    Name = "Jenkins-Master"                    # Tag to identify instance
  }
}

# EC2 instance for Jenkins Slave
resource "aws_instance" "jenkins_slave" {
  ami           = var.ami_id                       # Same AMI as master
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]  # Use SG by ID
  tags = {
    Name = "Jenkins-Slave"
  }
}

# Create an S3 bucket to store Jenkins build artifacts
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = var.s3_bucket_name  # Bucket name must be globally unique

  tags = {
    Name        = "jenkins-artifacts"
    Environment = "Dev"
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.jenkins_artifacts.id  # Reference the S3 bucket created above

  versioning_configuration {
    status = "Enabled"  # Enables object versioning for backup and rollback
  }
}



## 📦 `variables.tf`

```hcl
# AWS region where resources will be created
variable "aws_region" {
  default = "us-east-1"
}

# AMI ID for EC2 instances
variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  default     = "ami-02f624c08a83ca16f"
}

# SSH key pair name to access EC2
variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

# Name for the S3 bucket
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}
```

---

## 💠 `terraform.tfvars`

```hcl
# Provide your actual EC2 key pair and a globally unique S3 bucket name
key_name        = "my-Key pair"
s3_bucket_name  = "my-jenkins-artifacts-bucket-1234"
```

---

## 📤 `outputs.tf`

```hcl
# Output values to display after deployment
output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins_slave_public_ip" {
  value = aws_instance.jenkins_slave.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.jenkins_artifacts.bucket
}
```

---

## ✅ Alternative: `main.tf` (Single File Version)

> 🔁 Use this version if you prefer combining everything into one file.

```hcl
# Specify the AWS provider and region
provider "aws" {
  region = "us-east-1"  # AWS region where resources will be created
}

# Create a security group for Jenkins and Tomcat
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"                  # Name of the security group
  description = "Allow SSH, Jenkins UI, and HTTP access"  # Description of the security group

  # Inbound rule to allow SSH access from anywhere
  ingress {
    description = "Allow SSH"                 # Rule description
    from_port   = 22                          # Start of port range
    to_port     = 22                          # End of port range
    protocol    = "tcp"                       # Protocol type
    cidr_blocks = ["0.0.0.0/0"]               # Allow from all IPs (not recommended for production)
  }

  # Inbound rule to allow access to Jenkins UI
  ingress {
    description = "Allow Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule to allow access to Tomcat (HTTP)
  ingress {
    description = "Allow Tomcat HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all traffic (default for most SGs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"                        # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tagging the security group
  tags = {
    Name = "jenkins-sg"                       # Tag for identifying the SG
  }
}

# Create the Jenkins Master EC2 instance
resource "aws_instance" "jenkins_master" {
  ami                    = "ami-02f624c08a83ca16f"   # Amazon Linux 2 AMI ID
  instance_type          = "t2.micro"                # Instance type
  key_name               = "my-Key pair"             # EC2 Key Pair name (ensure it matches exactly)
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]  # Attach the security group
  availability_zone      = "us-east-1a"              # Deploy to this specific AZ

  tags = {
    Name = "Jenkins-Master"                          # Tag to identify the instance
  }
}

# Create the Jenkins Slave EC2 instance
resource "aws_instance" "jenkins_slave" {
  ami                    = "ami-02f624c08a83ca16f"   # Amazon Linux 2 AMI ID
  instance_type          = "t2.micro"                # Instance type
  key_name               = "my-Key pair"             # EC2 Key Pair name (ensure it matches exactly)
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]  # Attach the security group
  availability_zone      = "us-east-1b"              # Deploy to a different AZ for HA

  tags = {
    Name = "Jenkins-Slave"                           # Tag to identify the instance
  }
}

# Create an S3 bucket to store Jenkins artifacts
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = "my-jenkins-artifacts-bucket-1234"  # Bucket name (must be globally unique)

  tags = {
    Name        = "jenkins-artifacts"          # Tag for identifying the bucket
    Environment = "Dev"                        # Environment tag
  }
}

# Enable versioning on the S3 bucket for artifact history
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.jenkins_artifacts.id   # Link to the previously defined bucket

  versioning_configuration {
    status = "Enabled"                          # Enable versioning
  }
}

# Output the public IP address of the Jenkins Master instance
output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}

# Output the public IP address of the Jenkins Slave instance
output "jenkins_slave_public_ip" {
  value = aws_instance.jenkins_slave.public_ip
}

# Output the name of the created S3 bucket
output "s3_bucket_name" {
  value = aws_s3_bucket.jenkins_artifacts.bucket
}

```

---

## 🧪 Step-by-Step Terraform CLI Usage

### Step 1: Initialize Terraform

```sh
terraform init
```

### Step 2: Format Terraform Code

```sh
terraform fmt
```

### Step 3: Validate Configuration

```sh
terraform validate
```

### Step 4: Plan the Deployment

```sh
terraform plan
```

### Step 5: Apply the Configuration

```sh
terraform apply -auto-approve
```

### Step 6: Verify the Deployment

```sh
aws ec2 describe-instances
aws s3 ls
```

### Step 7: Destroy the Infrastructure (If Needed)

```sh
terraform destroy -auto-approve
```

