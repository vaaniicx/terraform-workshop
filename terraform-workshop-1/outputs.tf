# Zeigt die öffentliche DNS-Adresse der EC2-Instanz an nach einem erfolgreichen terraform apply
output "ec2_web_server_public_dns" {
  description = "Output Public DNS of the EC2 instance"
  value       = aws_instance.server.public_dns
}
