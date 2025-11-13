output "elb-dns-name" {
  description = "DNS Name of the Load Balancer"
  value       = aws_lb.lb.dns_name
}
