output "prometheus_private_ip" {
  value = tolist(aws_instance.prometheus_ec2[*].private_ip)[0]
}

output "jenkins_private_ip" {
  value = tolist(aws_instance.jenkins_ec2[*].private_ip)[0]
}

output "prometheus_public_ip" {
  description = "Public IP address of the Prometheus EC2 instance"
  value       = aws_instance.prometheus_ec2.public_ip
}
/*
output "prometheus_public_dns" {
  description = "Public DNS name of the Prometheus EC2 instance"
  value       = aws_instance.prometheus_ec2.public_dns
}
*/
output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_ec2.public_ip
}
/*
output "jenkins_public_dns" {
  description = "Public DNS name of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_ec2.public_dns
}
*/

output "jenkins_instance_id" {
  description = "Instance ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_ec2.id
}

output "prometheus_instance_id" {
  description = "Instance ID of the Prometheus EC2 instance"
  value       = aws_instance.prometheus_ec2.id
}