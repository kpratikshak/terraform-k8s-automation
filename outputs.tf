output "private_key_path" {
  value = local_sensitive_file.private_key.filename
  description = "Path to the saved SSH private key."
}

output "jenkins_server_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "ansible_server_ip" {
  value = aws_instance.ansible_server.public_ip
}

output "k8s_master_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "k8s_worker_ip" {
  value = aws_instance.k8s_worker.public_ip
}

output "petstore_app_dns" {
  value = aws_lb.petstore_alb.dns_name
  description = "DNS name of the ALB. Access via http://<dns-name>"
}
