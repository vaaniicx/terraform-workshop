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

# Erstellen eines eigenen VPCs
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block # definiert in variables.tf / terraform.tfvars

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Erstellen eines Internet Gateways
# Wird benötigt, um eine Verbindung zwischen VPC und Internet herzustellen.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # verwendet das oben definierte VPC

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Erstellen eines (öffentlichen) Subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id       # verwendet das oben definierte VPC
  cidr_block              = var.subnet_cidr_block # definiert in variables.tf / terraform.tfvars
  map_public_ip_on_launch = true                  # Automatische Zuweisung öffentlicher Adressen für Instanzen

  tags = {
    Name = "${var.project_name}-subnet-public"
  }
}

# Erstellen einer öffentlichen Routing-Tabelle
# Leitet ausgehenden Verkehr über das Internet weiter => Subnet wird öffentlich erreichbar
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # verwendet das oben definierte VPC

  route {
    cidr_block = "0.0.0.0/0" # jeglicher Verkehr
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# Verknüpfung Subnet & Routing-Tabelle
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.public.id      # verwendet das oben definierte Subnets
  route_table_id = aws_route_table.public.id # verwendet die oben definierte Routing-Tabelle
}

# --------------------------------------------------
# Security Group
# --------------------------------------------------

# Erstelle Sicherheitsgruppe
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg"
  description = "Allow HTTP inbound and all outbound traffic"
  vpc_id      = aws_vpc.main.id

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
# Network Interface and Elastic IP
# --------------------------------------------------

# Netzwerkschnittstelle
resource "aws_network_interface" "main" {
  subnet_id       = aws_subnet.public.id
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.web.id]

  tags = {
    Name = "${var.project_name}-eni"
  }
}

# Statisch öffentliche IP-Adresse (Elastic IP)
resource "aws_eip" "eip" {
  network_interface = aws_network_interface.main.id # verwendet die oben definierte Netzwerkschnittstelle
  domain            = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}

# --------------------------------------------------
# AWS EC2 Instance
# --------------------------------------------------

# Erstellen der EC2-Instanz
resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu_latest.id # verwendet die oben definierte AMI
  instance_type = var.instance_type             # gesetzt über variables.tf / terraform.tfvars
  user_data     = file("apache-web-server.sh")  # Automatische Ausführung des Shell-Scripts (Webserver)

  network_interface {
    network_interface_id = aws_network_interface.main.id
    device_index         = 0
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}