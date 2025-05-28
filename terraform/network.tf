// AWS VPC
resource "aws_vpc" "base-vpc" {
  cidr_block = "172.21.0.0/24"
  tags = {
    Name = "base-vpc"
  }
}

// AWS Subnet
resource "aws_subnet" "base-sn-za-pro-pub-00" {
  vpc_id                  = aws_vpc.base-vpc.id
  cidr_block              = "172.21.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
  tags = {
    Name = "base-sn-za-pro-pub-00"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "base-ig" {
  vpc_id = aws_vpc.base-vpc.id
  tags = {
    Name = "base-ig"
  }
}

// Routing table for public subnet
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

// Set new main_route_table as main
resource "aws_main_route_table_association" "base-rta-default" {
  vpc_id         = aws_vpc.base-vpc.id
  route_table_id = aws_route_table.base-rt-pub-main.id
}


resource "aws_security_group" "base-sg-ec2" {
  name   = "base-sg-ec2"
  description = "Base security group for EC2 instances"
  vpc_id = aws_vpc.base-vpc.id
}


resource "aws_security_group_rule" "base-sr-internet-to-ec2-ssh" {
  # checkov:skip=CKV_AWS_24: For demonstration purposes only, this rule allows SSH access from anywhere.
  # This is not recommended for production environments.
  security_group_id = aws_security_group.base-sg-ec2.id
  description = "Allow SSH access from the Internet"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "base-sr-internet-to-ec2-icmp" {
  security_group_id = aws_security_group.base-sg-ec2.id
  description = "Allow ICMP access from the Internet"
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "base-sr-all-outbund" {
  security_group_id = aws_security_group.base-sg-ec2.id
  description = "Allow all outbound traffic to the Internet"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "prometheus-sg-front-end" {
  name   = "prometheus-sg-front-end"
  description = "Security group for Prometheus front-end"
  vpc_id = aws_vpc.base-vpc.id
}

resource "aws_security_group" "exporter-sg-front-end" {
  name   = "exporter-sg-front-end"
  description = "Security group for Exporter front-end"
  vpc_id = aws_vpc.base-vpc.id
}

resource "aws_security_group" "grafana-sg-front-end" {
  name   = "grafana-sg-front-end"
  description = "Security group for Grafana front-end"
  vpc_id = aws_vpc.base-vpc.id
}

resource "aws_security_group" "jenkins-sg-front-end" {
  name   = "jenkins-sg-front-end"
  description = "Security group for Jenkins front-end"
  vpc_id = aws_vpc.base-vpc.id
}

// Allow access from the Internet to front end ports
resource "aws_security_group_rule" "prometheus-sr-internet-to-front-end-9090" {
  description       = "Allow Prometheus UI access from the Internet on port 9090"
  security_group_id = aws_security_group.prometheus-sg-front-end.id
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "grafana-sr-internet-to-front-end-3000" {
  description       = "Allow Grafana UI access from the Internet on port 3000"
  security_group_id = aws_security_group.grafana-sg-front-end.id
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "exporter-sr-internet-to-front-end-9100" {
  description       = "Allow Node Exporter access from the Internet on port 9100"
  security_group_id = aws_security_group.exporter-sg-front-end.id
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

}
resource "aws_security_group_rule" "jenkins-sr-internet-to-front-end-8080" {
  description       = "Allow Jenkins UI access from the Internet on port 8080"
  security_group_id = aws_security_group.jenkins-sg-front-end.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}