provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.test-vpc.id
  tags = {
    Name = "test-vpc-gw"
  }
}

resource "aws_route_table" "test-route-table" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

resource "aws_subnet" "test-vpc-subnet-1" {
  vpc_id            = aws_vpc.test-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "test-vpc-subnet-1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.test-vpc-subnet-1.id
  route_table_id = aws_route_table.test-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.test-vpc.id

  tags = {
    Name = "Traffic"
  }
  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH traffic"
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
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.test-vpc-subnet-1.id
  private_ips     = ["10.0.0.10"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_eip" "web-server-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.0.10"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_instance" "web-server" {
  ami               = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  key_name          = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }
  tags = {
    Name = "web-server"
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo your very first web server > /var/www/html/index.html'
            EOF
}
