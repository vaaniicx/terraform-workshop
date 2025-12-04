output "elb-dns-name" {
  description = "DNS Name of the Load Balancer"
  value       = aws_lb.lb.dns_name
}

# Zeigt die IP-Adresse des EC2-Instanzen an nach einem erfolgreichen Terraform Apply
# Diese IP-Adresse kann verwendet werden, um auf die EC2-Instanz zuzugreifen
# Die IP wird im Terminal angezeigt
