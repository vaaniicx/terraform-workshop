output "ec2_web_server_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.lb.public_ip
}

# Zeigt die IP-Adresse des EC2-Instanzen an nach einem erfolgreichen Terraform Apply
# Diese IP-Adresse kann verwendet werden, um auf die EC2-Instanz zuzugreifen
# Die IP wird im Terminal angezeigt
