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

# Verwendung des (bestehenden) Standard-VPCs von AWS.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block # definiert in variables.tf / terraform.tfvars

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Erstellen eines Internet Gateways
# Wird benötigt, um eine Verbindung zwischen VPC und Internet herzustellen.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # definiert in variables.tf / terraform.tfvars

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Erstelle öffentliches Subnet in Availability-Zone us-east-1a
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id # verwendet oben definiertes VPC
  cidr_block              = "10.0.11.0/24"  # eigener IP-Bereich
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Automatische Zuweisung öffentlicher Adressen für Instanzen

  tags = {
    Name = "${var.project_name}-subnet-a"
  }
}

# Erstelle öffentliches Subnet in Availability-Zone us-east-1b
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id # verwendet oben definiertes VPC
  cidr_block              = "10.0.12.0/24"  # eigener IP-Bereich
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true # Automatische Zuweisung öffentlicher Adressen für Instanzen

  tags = {
    Name = "${var.project_name}-subnet-b"
  }
}

# Erstellen einer öffentlichen Routing-Tabelle
# Leitet ausgehenden Verkehr über das Internet Gateway weiter => Subnet wird öffentlich erreichbar
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  # jeglicher Verkehr
    gateway_id = aws_internet_gateway.main.id # verwendet oben definierten Internet-Gateway
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# Verknüpfung Subnet A & Routing-Tabelle
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id    # verwendet oben definiertes Subnet A
  route_table_id = aws_route_table.public.id # verwendet oben definierte Routing-Tabelle
}

# Verknüpfung Subnet B & Routing-Tabelle
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id    # verwendet oben definiertes Subnet B
  route_table_id = aws_route_table.public.id # verwendet oben definierte Routing-Tabelle
}

# --------------------------------------------------
# Security Groups
# --------------------------------------------------

# Erstelle Sicherheitsgruppe für den Loadbalancer
resource "aws_security_group" "lb" {
  name   = "${var.project_name}-sg-lb"
  vpc_id = aws_vpc.main.id

  # Ingress / eingehende Regel
  # Erlaubt eingehenden HTTP-Verkehr auf Port 80
  # Notwendig, damit der Webserver öffentlich erreichbar ist.
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"         # TCP
    cidr_blocks = ["0.0.0.0/0"] # Zugriff von überall
  }

  # Egress/Ausgehende Regel
  # Erlaubt der Instanz jeglichen ausgehenden Verkehr
  # Damit Updates wie apt-get update funktionieren (siehe apacke-web-server.sh).
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # alle Protokolle
    cidr_blocks = ["0.0.0.0/0"] # Zugriff von überall
  }

  tags = {
    Name = "${var.project_name}-sg-lb"
  }
}

# Erstelle Sicherheitsgruppe für die Instanz
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
    Name = "${var.project_name}-sg-web"
  }
}

# --------------------------------------------------
# Load Balancer
# --------------------------------------------------

# Erstelle Application-Loadbalancer
resource "aws_lb" "lb" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.lb.id]                       # verwendet die oben definierte Sicherheitsgruppe für den Loadbalancer
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] # Bereitstellung des Loadbalancers in zwei Subnetzen (unterschiedliche Availability-Zones)

  tags = {
    Name = "${var.project_name}-lb"
  }
}

# Erstellung der Target-Group für den Loadbalancer
# Sammlung aller Instanzen, an die der Loadbalancer weiterleiten kann
resource "aws_lb_target_group" "target" {

  # Regelmäßiger Health-Check, um inaktive Instanzen aus dem Loadbalancing zu entfernen
  health_check {
    interval            = 10 # Zeit in Sekunden
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "${var.project_name}-target"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"      # direkte Weiterleitung an Instanzen
  vpc_id      = aws_vpc.main.id # verwendet oben definiertes VPC
}

# Erstellen des Loadbalancer Listeners
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  # Weiterleitung an die Target-Group
  default_action {
    target_group_arn = aws_lb_target_group.target.arn
    type             = "forward"
  }
}

# --------------------------------------------------
# AWS EC2 Instance
# --------------------------------------------------

# Erstellen der EC2-Instanzen
resource "aws_instance" "server" {
  ami                    = data.aws_ami.ubuntu_latest.id                                          # verwendet die oben definierte AMI
  instance_type          = var.instance_type                                                      # gesetzt über variables.tf / terraform.tfvars
  count                  = 2                                                                      # erstelle 2 Instanzen
  subnet_id              = element([aws_subnet.public_a.id, aws_subnet.public_b.id], count.index) # Instanz 1: Subnet A (us-east-1a), Instanz 2: Subnet B (us-east-1b)
  vpc_security_group_ids = [aws_security_group.web.id]                                            # verwendet die oben definierte Sicherheitsgruppe
  user_data              = file("apache-web-server.sh")                                           # Automatische Ausführung des Shell-Scripts (Webserver)

  tags = {
    Name = "${var.project_name}-ec2-${count.index}"
  }
}

# Verknüpfung Instanzen & Loadbalancer
resource "aws_lb_target_group_attachment" "ec2_attach" {
  count            = length(aws_instance.server)         # Anzahl Instanzen
  target_group_arn = aws_lb_target_group.target.arn      # verwendet oben definierte Target-Group
  target_id        = aws_instance.server[count.index].id # ID der Instanz
}