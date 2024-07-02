# Define Terrraform Providers and Backend
terraform {
  required_version = "> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#-----------------------------------------
# Default provider: AWS
#-----------------------------------------
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  shared_config_files      = ["~/.aws/config"]
  #profile                  = "prom_infradmin"
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "prometheus-vpc" {
  cidr_block = "172.21.0.0/24"
  tags = {
    Name = "prometheus-vpc"
  }
}

# Subnet
resource "aws_subnet" "prometheus-sn-za-pro-pub-00" {
  vpc_id                  = aws_vpc.prometheus-vpc.id
  cidr_block              = "172.21.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
  tags = {
    Name = "prometheus-sn-za-pro-pub-00"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "prometheus-ig" {
  vpc_id = aws_vpc.prometheus-vpc.id
  tags = {
    Name = "prometheus-ig"
  }
}

# Routing table for public subnet (access to Internet)
resource "aws_route_table" "prometheus-rt-pub-main" {
  vpc_id = aws_vpc.prometheus-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prometheus-ig.id
  }

  tags = {
    Name = "prometheus-rt-pub-main"
  }
}

# Set new main_route_table as main
resource "aws_main_route_table_association" "prometheus-rta-default" {
  vpc_id         = aws_vpc.prometheus-vpc.id
  route_table_id = aws_route_table.prometheus-rt-pub-main.id
}

# Create a "base" Security Group to be assigned to all EC2 instances
resource "aws_security_group" "prometheus-sg-base-ec2" {
  name   = "prometheus-sg-base-ec2"
  vpc_id = aws_vpc.prometheus-vpc.id
}

# DANGEROUS!!
# Allow access from the Internet to port 22 (SSH) in the EC2 instances
resource "aws_security_group_rule" "prometheus-sr-internet-to-ec2-ssh" {
  security_group_id = aws_security_group.prometheus-sg-base-ec2.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

# Allow access from the Internet for ICMP protocol (e.g. ping) to the EC2 instances
resource "aws_security_group_rule" "prometheus-sr-internet-to-ec2-icmp" {
  security_group_id = aws_security_group.prometheus-sg-base-ec2.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

# Allow all outbound traffic to Internet
resource "aws_security_group_rule" "prometheus-sr-all-outbund" {
  security_group_id = aws_security_group.prometheus-sg-base-ec2.id
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Create a Security Group for the Front end Server
resource "aws_security_group" "prometheus-sg-front-end" {
  name   = "prometheus-sg-front-end"
  vpc_id = aws_vpc.prometheus-vpc.id
}

# Allow access from the Internet to port 9090 in the EC2 instances
resource "aws_security_group_rule" "prometheus-sr-internet-to-front-end" {
  security_group_id = aws_security_group.prometheus-sg-front-end.id
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

# Upload a Private Key Pair for SSH Instance Authentication
resource "aws_key_pair" "prometheus-kp-config-user" {
  key_name   = "prometheus-kp-config-user"
  public_key = file("~/keys/prometheus-kp-config-user-ecdsa.pub")
}

data "aws_ami" "ubuntu-23-04-arm64-minimal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd/ubuntu-lunar-23.04-arm64-minimal-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Front end server running Ubuntu 23.04 ARM Minimal.
resource "aws_instance" "prometheus-ec-a" {
  ami                    = data.aws_ami.ubuntu-23-04-arm64-minimal.id
  instance_type          = "t4g.micro"
  subnet_id              = aws_subnet.prometheus-sn-za-pro-pub-00.id
  key_name               = "prometheus-kp-config-user"
  vpc_security_group_ids = [aws_security_group.prometheus-sg-base-ec2.id, aws_security_group.prometheus-sg-front-end.id]
  tags = {
    "Name"         = "prometheus-ec-a"
    "private_name" = "prometheus-ec-a"
    "public_name"  = "www"
    "app"          = "front-end"
    "app_ver"      = "2.3"
    "os"           = "ubuntu"
    "os_ver"       = "23.04"
    "os_arch"      = "arm64"
    "environment"  = "pro"
    "cost_center"  = "green-department"
  }
}

resource "aws_instance" "prometheus-ec-b" {
  ami                    = data.aws_ami.ubuntu-23-04-arm64-minimal.id
  instance_type          = "t4g.micro"
  subnet_id              = aws_subnet.prometheus-sn-za-pro-pub-00.id
  key_name               = "prometheus-kp-config-user"
  vpc_security_group_ids = [aws_security_group.prometheus-sg-base-ec2.id, aws_security_group.prometheus-sg-front-end.id]
  tags = {
    "Name"         = "prometheus-ec-b"
    "private_name" = "prometheus-ec-b"
    "public_name"  = "www"
    "app"          = "front-end"
    "app_ver"      = "2.3"
    "os"           = "ubuntu"
    "os_ver"       = "23.04"
    "os_arch"      = "arm64"
    "environment"  = "pro"
    "cost_center"  = "blue-department"
  }
}
