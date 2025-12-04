# Zeigt den DNS-Namen des Loadbalancers nach einem erfolgreichen terraform apply an
output "elb-dns-name" {
  description = "DNS Name of the Load Balancer"
  value       = aws_lb.lb.dns_name # oder public_ip
}
