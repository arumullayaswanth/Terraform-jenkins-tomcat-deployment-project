output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins_slave_public_ip" {
  value = aws_instance.jenkins_slave.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.jenkins_artifacts.bucket
}
