provider "aws" {
  region = var.aws_region
}

# Security Group
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

# Jenkins Master EC2
resource "aws_instance" "jenkins_master" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  security_groups = [aws_security_group.jenkins_sg.name]
  tags = {
    Name = "Jenkins-Master"
  }
}

# Jenkins Slave EC2
resource "aws_instance" "jenkins_slave" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  tags = {
    Name = "Jenkins-Slave"
  }
}


# S3 Bucket
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "jenkins-artifacts"
    Environment = "Dev"
  }
}

# Enable versioning for the created S3 bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}
