resource "aws_vpc" "base_vpc" {
  # checkov:skip=CKV2_AWS_12: SSM remote access
  cidr_block           = "172.21.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "base-vpc"
  }
}

# Create an IAM role for VPC flow logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/base-vpc"
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
  retention_in_days = 365
}


# Enable VPC flow logs
resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
  vpc_id               = aws_vpc.base_vpc.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
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
  # checkov:skip=CKV_AWS_130: SSM Remote Access
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

resource "aws_default_security_group" "restrict_default" {
  vpc_id = aws_vpc.base_vpc.id

  # ingress {
  #   self      = true
  #   from_port = 0
  #   to_port   = 0
  #   protocol    = "-1" # all protocols
  #   cidr_blocks = []
  # }

  egress {
    self        = true
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols`
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Restrict Default SG"
  }
}


