# --------------------------------------------------
# Data Source
# --------------------------------------------------

# Holt sich die aktuellste Ubuntu-AMI-Version (Ubuntu 24.04), die von Canonical veröffentlicht wurde.
# Das hat den Vorteil, dass die AMI-ID nicht manuell aktualisiert werden muss.
data "aws_ami" "ubuntu_latest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# --------------------------------------------------
# Network
# --------------------------------------------------

# Verwendung des (bestehenden) Standard-VPCs von AWS
resource "aws_default_vpc" "default" {}

# --------------------------------------------------
# Security Group
# --------------------------------------------------

# Erstelle Sicherheitsgruppe
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg"
  description = "Allow HTTP inbound and all outbound traffic"
  vpc_id      = aws_default_vpc.default.id # verwendet das oben definierte VPC

  # Ingress / eingehende Regel
  # Erlaubt eingehenden HTTP-Verkehr auf Port 80
  # Notwendig, damit der Webserver öffentlich erreichbar ist.
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"         # TCP
    cidr_blocks = ["0.0.0.0/0"] # Zugriff von überall
  }

  # Egress/Ausgehende Regel
  # Erlaubt der Instanz jeglichen ausgehenden Verkehr
  # Damit Updates wie apt-get update funktionieren (siehe apacke-web-server.sh).
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # alle Protokolle
    cidr_blocks = ["0.0.0.0/0"] # Zugriff von überall
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# --------------------------------------------------
# AWS EC2 Instance
# --------------------------------------------------

# Erstellen der EC2-Instanz
resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu_latest.id # verwendet die oben definierte AMI
  instance_type               = var.instance_type             # gesetzt über variables.tf / terraform.tfvars
  vpc_security_group_ids      = [aws_security_group.web.id]   # verwendet die oben definierte Sicherheitsgruppe
  associate_public_ip_address = true                          # Zuweisung öffentlicher IP
  user_data                   = file("apache-web-server.sh")  # Automatische Ausführung des Shell-Scripts (Webserver)

  tags = {
    Name = "${var.project_name}-ec2"
  }
}