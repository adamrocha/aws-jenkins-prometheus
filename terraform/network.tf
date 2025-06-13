resource "aws_vpc" "base_vpc" {
  # checkov:skip=CKV2_AWS_11: fix later
  cidr_block           = "172.21.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "base-vpc"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "base_ig" {
  vpc_id = aws_vpc.base_vpc.id
  tags = {
    Name = "base-ig"
  }
}

// AWS Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.base_vpc.id
  cidr_block              = "172.21.0.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

// Routing table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.base_vpc.id
  /*
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.base_ig.id
  }
  */
  tags = {
    Name = "public-rt"
  }
}

# Route internet traffic to the Internet Gateway
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.base_ig.id
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
/*
# Elastic IP
resource "aws_eip" "public_ip" {
  domain = "vpc"
}

# Associate EIP to the ENI
resource "aws_eip_association" "prom_eip" {
  allocation_id        = aws_eip.public_ip.id
  network_interface_id = aws_network_interface.prometheus_nic.id
}

# Associate EIP to the ENI
resource "aws_eip_association" "jenkins_eip" {
  allocation_id        = aws_eip.public_ip.id
  network_interface_id = aws_network_interface.jenkins_nic.id
}
/*
// Set new main_route_table as main
resource "aws_main_route_table_association" "default" {
  vpc_id         = aws_vpc.base_vpc.id
  route_table_id = aws_route_table.public_rt.id
}
# Associate the public subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
*/
resource "aws_security_group_rule" "base_sg_internet_to_ec2_icmp" {
  security_group_id = aws_security_group.base_sg_ec2.id
  description       = "Allow ICMP access from the Internet"
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "base_sg_all_outbound" {
  security_group_id = aws_security_group.base_sg_ec2.id
  description       = "Allow all outbound traffic to the Internet"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "base_sg_ec2" {
  description = "Base security group for EC2 instances"
  name        = "base-sg-ec2"
  vpc_id      = aws_vpc.base_vpc.id

  ingress {
    description = "Allow SSH access from the Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prometheus_sg_front_end" {
  name        = "prometheus-sg-front-end"
  description = "Security group for Prometheus front-end access"
  vpc_id      = aws_vpc.base_vpc.id

  ingress {
    description = "Allow Prometheus UI access from the Internet"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "exporter_sg_front_end" {
  name        = "exporter-sg-front-end"
  description = "Security group for Exporter front-end access"
  vpc_id      = aws_vpc.base_vpc.id

  ingress {
    description = "Security group for Exporter front-end access"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "grafana_sg_front_end" {
  name        = "grafana-sg-front-end"
  description = "Security group for Grafana front-end access"
  vpc_id      = aws_vpc.base_vpc.id

  ingress {
    description = "Allow Grafana UI access from the Internet"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_sg_front_end" {
  name        = "jenkins-sg-front-end"
  description = "Security group for Jenkins front-end access"
  vpc_id      = aws_vpc.base_vpc.id

  ingress {
    description = "Allow Jenkins UI access from the Internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
resource "aws_security_group_rule" "exporter_sr_internet_to_front_end_9100" {
  description       = "Allow Node Exporter access from the Internet on port 9100"
  security_group_id = aws_security_group.exporter_sg_front_end.id
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
*/