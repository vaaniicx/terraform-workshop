# Zeigt die öffentliche IP-Adresse der EC2-Instanz nach einem erfolgreichen terraform apply an
# Kann verwendet werden, um auf die EC2-Instanz zuzugreifen
output "ec2_web_server_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.lb.public_ip
}