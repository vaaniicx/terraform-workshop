output "ec2_web_server_public_dns" {
  description = "Output Public DNS of the EC2 instance"
  value       = aws_instance.server.public_dns
}

# Zeigt die IP-Adresse des EC2-Instanzen an nach einem erfolgreichen Terraform Apply
# Diese IP-Adresse kann verwendet werden, um auf die EC2-Instanz zuzugreifen
# Die IP wird im Terminal angezeigt


