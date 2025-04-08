
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

```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, HTTP, and Tomcat"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_master" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  security_groups = [aws_security_group.jenkins_sg.name]
  tags = {
    Name = "Jenkins-Master"
  }
}

resource "aws_instance" "jenkins_slave" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  tags = {
    Name = "Jenkins-Slave"
  }
}

resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "jenkins-artifacts"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

---

## 📦 `variables.tf`

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  default     = "ami-02f624c08a83ca16f"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}
```

---

## 🛠️ `terraform.tfvars`

```hcl
key_name        = "my-Key pair"
s3_bucket_name  = "my-jenkins-artifacts-bucket-1234"
```

---

## 📤 `outputs.tf`

```hcl
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

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, Jenkins UI, and HTTP access"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Tomcat HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

resource "aws_instance" "jenkins_master" {
  ami                    = "ami-02f624c08a83ca16f"
  instance_type          = "t2.micro"
  key_name               = "my-Key pair"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  availability_zone = "us-east-1a"

  tags = {
    Name = "Jenkins-Master"
  }
}

resource "aws_instance" "jenkins_slave" {
  ami                    = "ami-02f624c08a83ca16f"
  instance_type          = "t2.micro"
  key_name               = "my-Key pair"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  availability_zone = "us-east-1b"

  tags = {
    Name = "Jenkins-Slave"
  }
}

resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = "my-jenkins-artifacts-bucket-1234"

  tags = {
    Name        = "jenkins-artifacts"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

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

> ✅ **Tip**: Always run `terraform init`, `terraform plan`, and `terraform apply` after making changes.

