resource "aws_instance" "prometheus_ec2" {
  ami                  = var.ami_id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  instance_type        = var.instance_type
  monitoring           = true
  ebs_optimized        = true

  volume_tags = {
    Name = "prometheus-ec2-root-volume"
  }

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.prometheus_nic.id
    device_index         = 0
  }

  tags = {
    Name         = "prometheus-ec2"
    private_name = "prometheus-ec2"
    public_name  = "www"
    app          = "front-end"
    app_ver      = "2.3"
    os           = "ubuntu"
    os_ver       = "24.04"
    os_arch      = "arm64"
    environment  = "dev"
    cost_center  = "department-a"
  }
}

resource "aws_network_interface" "prometheus_nic" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["172.21.0.20"]
  security_groups = [
    aws_default_security_group.restrict_default.id,
    aws_security_group.prometheus_sg_front_end.id,
    aws_security_group.exporter_sg_front_end.id,
    aws_security_group.grafana_sg_front_end.id,
    aws_security_group.jenkins_sg_front_end.id
  ]
  tags = {
    Name = "primary-network-interface"
  }
}

resource "aws_instance" "jenkins_ec2" {
  ami                  = var.ami_id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  instance_type        = var.instance_type
  monitoring           = true
  ebs_optimized        = true

  volume_tags = {
    Name = "jenkins-ec2-root-volume"
  }

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.jenkins_nic.id
    device_index         = 0
  }

  tags = {
    Name         = "jenkins-ec2"
    private_name = "jenkins-ec2"
    public_name  = "www"
    app          = "front-end"
    app_ver      = "2.3"
    os           = "ubuntu"
    os_ver       = "24.04"
    os_arch      = "arm64"
    environment  = "dev"
    cost_center  = "department-b"
  }
}

resource "aws_network_interface" "jenkins_nic" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["172.21.0.21"]
  security_groups = [
    aws_default_security_group.restrict_default.id,
    aws_security_group.exporter_sg_front_end.id,
    aws_security_group.jenkins_sg_front_end.id
  ]
  tags = {
    Name = "primary-network-interface"
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