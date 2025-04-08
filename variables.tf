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
