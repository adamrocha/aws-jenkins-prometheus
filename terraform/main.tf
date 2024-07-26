# Define Terrraform Backend and Providers
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
resource "aws_vpc" "base-vpc" {
  cidr_block = "172.21.0.0/24"
  tags = {
    Name = "base-vpc"
  }
}

# Subnet
resource "aws_subnet" "base-sn-za-pro-pub-00" {
  vpc_id                  = aws_vpc.base-vpc.id
  cidr_block              = "172.21.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
  tags = {
    Name = "base-sn-za-pro-pub-00"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "base-ig" {
  vpc_id = aws_vpc.base-vpc.id
  tags = {
    Name = "base-ig"
  }
}

# Routing table for public subnet (access to Internet)
resource "aws_route_table" "base-rt-pub-main" {
  vpc_id = aws_vpc.base-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.base-ig.id
  }

  tags = {
    Name = "base-rt-pub-main"
  }
}

# Set new main_route_table as main
resource "aws_main_route_table_association" "base-rta-default" {
  vpc_id         = aws_vpc.base-vpc.id
  route_table_id = aws_route_table.base-rt-pub-main.id
}

# Create a "base" Security Group to be assigned to all EC2 instances
resource "aws_security_group" "base-sg-ec2" {
  name   = "base-sg-ec2"
  vpc_id = aws_vpc.base-vpc.id
}

# DANGEROUS!!
# Allow access from the Internet to port 22 (SSH) in the EC2 instances
resource "aws_security_group_rule" "base-sr-internet-to-ec2-ssh" {
  security_group_id = aws_security_group.base-sg-ec2.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

# Allow access from the Internet for ICMP protocol (e.g. ping) to the EC2 instances
resource "aws_security_group_rule" "base-sr-internet-to-ec2-icmp" {
  security_group_id = aws_security_group.base-sg-ec2.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

# Allow all outbound traffic to Internet
resource "aws_security_group_rule" "base-sr-all-outbund" {
  security_group_id = aws_security_group.base-sg-ec2.id
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Create a Security Group for Prometheus front end
resource "aws_security_group" "prometheus-sg-front-end" {
  name   = "prometheus-sg-front-end"
  vpc_id = aws_vpc.base-vpc.id
}

# Create a Security Group for Jenkins front end
resource "aws_security_group" "jenkins-sg-front-end" {
  name   = "jenkins-sg-front-end"
  vpc_id = aws_vpc.base-vpc.id
}

# Create a Security Group for exporter
resource "aws_security_group" "exporter-sg-front-end" {
  name   = "exporter-sg-front-end"
  vpc_id = aws_vpc.base-vpc.id
}

# Allow access from the Internet to port 9090 in the EC2 instances
resource "aws_security_group_rule" "prometheus-sr-internet-to-front-end-9090" {
  security_group_id = aws_security_group.prometheus-sg-front-end.id
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

resource "aws_security_group_rule" "prometheus-sr-internet-to-front-end-3000" {
  security_group_id = aws_security_group.prometheus-sg-front-end.id
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

resource "aws_security_group_rule" "exporter-sr-internet-to-front-end-9100" {
  security_group_id = aws_security_group.exporter-sg-front-end.id
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet

}

resource "aws_security_group_rule" "jenkins-sr-internet-to-front-end-8080" {
  security_group_id = aws_security_group.jenkins-sg-front-end.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Internet
}

# Upload a Private Key Pair for SSH Instance Authentication
resource "aws_key_pair" "aws-key-pair" {
  key_name   = "aws-key-pair"
  public_key = file("~/keys/aws-kp-ecdsa.pub")
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
resource "aws_instance" "prometheus-ec2" {
  ami           = data.aws_ami.ubuntu-23-04-arm64-minimal.id
  instance_type = "t4g.micro"
  key_name      = "aws-key-pair"
  network_interface {
    network_interface_id = aws_network_interface.prometheus-nic.id
    device_index         = 0
  }
  tags = {
    Name         = "prometheus-ec2"
    private_name = "prometheus-ec2"
    public_name  = "www"
    app          = "front-end"
    app_ver      = "2.3"
    os           = "ubuntu"
    os_ver       = "23.04"
    os_arch      = "arm64"
    environment  = "pro"
    cost_center  = "department-a"
  }
}

resource "aws_network_interface" "prometheus-nic" {
  subnet_id       = aws_subnet.base-sn-za-pro-pub-00.id
  private_ips     = ["172.21.0.20"]
  security_groups = [aws_security_group.base-sg-ec2.id,
                     aws_security_group.exporter-sg-front-end.id,
                     aws_security_group.prometheus-sg-front-end.id]
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "jenkins-ec2" {
  ami           = data.aws_ami.ubuntu-23-04-arm64-minimal.id
  instance_type = "t4g.micro"
  key_name      = "aws-key-pair"
  network_interface {
    network_interface_id = aws_network_interface.jenkins-nic.id
    device_index         = 0
  }
  tags = {
    Name         = "jenkins-ec2"
    private_name = "jenkins-ec2"
    public_name  = "www"
    app          = "front-end"
    app_ver      = "2.3"
    os           = "ubuntu"
    os_ver       = "23.04"
    os_arch      = "arm64"
    environment  = "pro"
    cost_center  = "department-b"
  }
}

resource "aws_network_interface" "jenkins-nic" {
  subnet_id       = aws_subnet.base-sn-za-pro-pub-00.id
  private_ips     = ["172.21.0.21"]
  security_groups = [aws_security_group.base-sg-ec2.id,
                     aws_security_group.exporter-sg-front-end.id,
                     aws_security_group.jenkins-sg-front-end.id]
  tags = {
    Name = "primary_network_interface"
  }
}