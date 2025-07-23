resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.env}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.env}-private-${count.index + 1}"
  }
}

# Reserves an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "${var.env}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.env}-nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.env}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

data "aws_availability_zones" "available" {
  state = "available"
}



#----------------------
# Security Group
#----------------------
resource "aws_security_group" "glue_sagemaker_lambda" {
  name        = "${var.env}-glue-sagemaker-lambda-sg"
  description = "Allow access to Glue, Sagemaker, Lambda"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "glue_sagemaker_lambda_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.glue_sagemaker_lambda.id
}

# ---------------------
# VPC endpoints
# ---------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [
    aws_route_table.private.id
  ]
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.env}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "glue" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.ap-southeast-2.glue"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.glue_sagemaker_lambda.id] # ✅ REQUIRED

  private_dns_enabled = true

  tags = {
    Name = "${var.env}-glue-endpoint"
  }
}

resource "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-southeast-2.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.glue_sagemaker_lambda.id]
  private_dns_enabled = true
  tags = {
    Name = "${var.env}-sagemaker-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-southeast-2.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.glue_sagemaker_lambda.id]
  private_dns_enabled = true
  tags = {
    Name = "${var.env}-sagemaker-runtime-endpoint"
  }
}
