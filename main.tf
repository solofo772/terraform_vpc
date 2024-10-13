# Configuration du fournisseur AWS avec les clés d'accès et la région
provider "aws" {
  region     = "eu-west-3"
}

# Création d'une VPC (Virtual Private Cloud) avec un bloc CIDR de 10.0.0.0/16
resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "demo_vpc"
  }
}

# Création de sous-réseaux privés
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3b"
  tags = {
    Name = "private-subnet-2"
  }
}

# Création de sous-réseaux publics
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"
  tags = {
    Name = "public-subnet-2"
  }
}

# Création de la passerelle Internet
resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-vpc-IGW"
  }
}

# Création de table de routage privée pour eu-west-3a
resource "aws_route_table" "private-route-table-1" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "private-route-table-1"
  }
}

resource "aws_route" "private-route-1" {
  route_table_id         = aws_route_table.private-route-table-1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway-1.id
}

resource "aws_route_table_association" "private-subnet-1-association" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-route-table-1.id
}

# Création de table de routage privée pour eu-west-3b
resource "aws_route_table" "private-route-table-2" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "private-route-table-2"
  }
}

resource "aws_route" "private-route-2" {
  route_table_id         = aws_route_table.private-route-table-2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway-2.id
}

resource "aws_route_table_association" "private-subnet-2-association" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-route-table-2.id
}

# Création de table de routage publique
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo-igw.id
}

resource "aws_route_table_association" "public-subnet-1-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-2-association" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}

# Créer les NAT Gateways pour chaque zone de disponibilité
resource "aws_eip" "nat-eip-1" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-1"
  }
}

resource "aws_nat_gateway" "nat-gateway-1" {
  allocation_id = aws_eip.nat-eip-1.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "nat-gateway-1"
  }
}

resource "aws_eip" "nat-eip-2" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-2"
  }
}

resource "aws_nat_gateway" "nat-gateway-2" {
  allocation_id = aws_eip.nat-eip-2.id
  subnet_id     = aws_subnet.public-subnet-2.id
  tags = {
    Name = "nat-gateway-2"
  }
}

# Règles de pare-feu / groupes de sécurité
resource "aws_security_group" "web-sg" {
  vpc_id = aws_vpc.demo-vpc.id
  name   = "web-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb_sg.id]  
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id = aws_vpc.demo-vpc.id
  name   = "db-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb_sg.id]

  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "db-sg"
  }
}

# Création d'un Target Group
resource "aws_lb_target_group" "web_target_group" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Web Target Group"
  }
}

# Création d'un Security Group pour l'ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.demo-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Autoriser l'accès depuis n'importe où, à ajuster selon vos besoins
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB Security Group"
  }
}

# Création d'un Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]  # Utilisation du groupe de sécurité de l'ALB
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]

  enable_deletion_protection = false

  tags = {
    Name = "web-alb"
  }
}

# Création d'un listener pour l'ALB
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}

# Enregistrement de la première instance publique dans le Target Group
resource "aws_lb_target_group_attachment" "web_target_group_attachment_1" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id        = aws_instance.private-instance.id
  port             = 80
}

# Enregistrement de la deuxième instance publique dans le Target Group
resource "aws_lb_target_group_attachment" "web_target_group_attachment_2" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id        = aws_instance.private-instance-b.id
  port             = 80
}
