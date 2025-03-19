# Upload a Private Key Pair for SSH Instance Authentication
resource "aws_key_pair" "aws-key-pair" {
  key_name   = "aws-key-pair"
  public_key = file("/opt/keys/aws-kp-ecdsa.pub")
}

data "aws_ami" "ubuntu-noble-24-04-arm64-minimal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-minimal-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Front end servers running Ubuntu 24.04 ARM micro
resource "aws_instance" "prometheus-ec2" {
  ami           = data.aws_ami.ubuntu-noble-24-04-arm64-minimal.id
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
    environment  = "dev"
    cost_center  = "department-a"
  }
}

resource "aws_network_interface" "prometheus-nic" {
  subnet_id   = aws_subnet.base-sn-za-pro-pub-00.id
  private_ips = ["172.21.0.20"]
  security_groups = [aws_security_group.base-sg-ec2.id,
    aws_security_group.prometheus-sg-front-end.id,
    aws_security_group.exporter-sg-front-end.id,
    aws_security_group.grafana-sg-front-end.id,
  aws_security_group.jenkins-sg-front-end.id]
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "jenkins-ec2" {
  ami           = data.aws_ami.ubuntu-noble-24-04-arm64-minimal.id
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
    environment  = "dev"
    cost_center  = "department-b"
  }
}

resource "aws_network_interface" "jenkins-nic" {
  subnet_id   = aws_subnet.base-sn-za-pro-pub-00.id
  private_ips = ["172.21.0.21"]
  security_groups = [aws_security_group.base-sg-ec2.id,
    aws_security_group.exporter-sg-front-end.id,
  aws_security_group.jenkins-sg-front-end.id]
  tags = {
    Name = "primary_network_interface"
  }
}