# Define a vpc
# 1. VPC Definition
resource "aws_vpc" "vpc" {
  cidr_block = "10.5.0.0/16" # think about bigger cidr /12 or /14 for scale
  tags = {
    Name = "${var.prefix}"
    createdBy = "infra-${var.prefix}/base"
  }
}

# --- NEW CODE START ---
# Data source to fetch the list of available AZs in the current region
# 2. Dynamic AZ Data Source (Scalability)
data "aws_availability_zones" "available" {
  state = "available"
}
# --- NEW CODE END ---

resource "aws_ssm_parameter" "vpc" {
  name = "/${var.prefix}/base/vpc_id"
  value = "${aws_vpc.vpc.id}"
  type  = "String"
}

# These SSM resources now need to reference the dynamically created subnets:
# by default put into internet subnet
# but a better way is to create vpc interface endpoints
#######################option 1
resource "aws_ssm_parameter" "subnet_a" {
  name  = "/${var.prefix}/base/subnet/a/id"
  # References the first public subnet (index 0)
  value = aws_subnet.public[0].id 
  type  = "String"
}

resource "aws_ssm_parameter" "subnet_b" {
  name  = "/${var.prefix}/base/subnet/b/id"
  # References the second public subnet (index 1)
  value = aws_subnet.public[1].id
  type  = "String"
}
#######################option 1 end
#######################option 2
# a. Create a Security Group for the VPC Endpoints
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "${var.prefix}-ssm-endpoint-sg"
  description = "Allows inbound HTTPS access to SSM VPC endpoints"
  vpc_id      = aws_vpc.vpc.id

  # Allow inbound HTTPS traffic from the entire VPC CIDR range (10.5.0.0/16)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  # Allow all outbound traffic (default best practice for service endpoints)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# b. Create the three required Interface Endpoints for Systems Manager (AWS PrivateLink)
# Note: These use the dynamically created public subnets from the previous recommendation.
# If you are deploying services primarily to private subnets, you should use those instead.

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.public[*].id # Use all public subnet IDs
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.public[*].id
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.public[*].id
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}
#######################option 2 end

# 6. Public Route Table (Routes to IGW)
# Routing table for public subnets
resource "aws_route_table" "public_subnet_routes" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "Public subnet routing table"
    createdBy = "infra-${var.prefix}/base"
  }
}

# 3. Internet Gateway (Public Access)
# Internet gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Public gateway"
    createdBy = "infra-${var.prefix}/base"
  }
}

# 7. Private Route Tables (Routes to NAT Gateway)
# --- NEW CODE START for priv subnet---
# Routing table for private subnets (routes to NAT Gateway)
resource "aws_route_table" "private_subnet_routes" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    # Route traffic to the NAT Gateway
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name      = "Private subnet routing table AZ ${count.index}"
    createdBy = "infra-${var.prefix}/base"
  }
}
# --- NEW CODE END ---

# --- REPLACE HARDCODED SUBNETS WITH THIS DYNAMIC BLOCK ---

# 5. Dynamic Subnet Definitions (Public and Private)
# Creates a Public Subnet for every available AZ
# Define the Public Subnets
resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  # CIDR: 10.5.0.0/24, 10.5.1.0/24, 10.5.2.0/24, etc.
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Public subnets should map public IPs

  tags = {
    Name      = "${var.prefix}-public-${data.aws_availability_zones.available.names[count.index]}"
    createdBy = "infra-${var.prefix}/base"
  }
}

# Creates a Private Subnet for every available AZ (Security)
# Define the Private Subnets
resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.vpc.id
  # cidrsubnet() is used to calculate new CIDRs dynamically (10.5.2.0/24, 10.5.3.0/24, etc.)
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + length(aws_subnet.public))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name      = "${var.prefix}-private-${data.aws_availability_zones.available.names[count.index]}"
    createdBy = "infra-${var.prefix}/base"
  }
}
# --- END NEW SUBNET BLOCK ---

# --- NEW CODE START ---
# 4. NAT Gateway (Secure Outbound Access for Private Subnets)
# Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  vpc        = true
  tags = {
    Name      = "NAT Gateway EIP"
    createdBy = "infra-${var.prefix}/base"
  }
}

# NAT Gateway placed in the first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # We'll use a new dynamic list structure
  tags = {
    Name      = "NAT Gateway"
    createdBy = "infra-${var.prefix}/base"
  }
  # Add a dependency to ensure NAT Gateway is created after IGW
  depends_on = [aws_internet_gateway.gw]
}
# --- NEW CODE END ---



#resource "aws_subnet" "public_subnet_a" {
#  vpc_id = "${aws_vpc.vpc.id}"
#  cidr_block = "10.5.0.0/24"
#  availability_zone = "${var.region}a"
#  tags = {
#    Name = "Public subnet A"
#    createdBy = "infra-${var.prefix}/base"
#  }
#}
#
#resource "aws_ssm_parameter" "subnet_a" {
#  name = "/${var.prefix}/base/subnet/a/id"
#  value = "${aws_subnet.public_subnet_a.id}"
#  type  = "String"
#}
#
#resource "aws_subnet" "public_subnet_b" {
#  vpc_id = "${aws_vpc.vpc.id}"
#  cidr_block = "10.5.1.0/24"
#  availability_zone = "${var.region}b"
#  tags = {
#    Name = "Public subnet B"
#    createdBy = "infra-${var.prefix}/base"
#  }
#}
#
#resource "aws_ssm_parameter" "subnet_b" {
#  name = "/${var.prefix}/base/subnet/b/id"
#  value = "${aws_subnet.public_subnet_b.id}"
#  type  = "String"
#}
#
## Here, you can add more subnets in other availability zones
#


# I have removed the existing association with a dynamic one
# --- REPLACE ALL EXISTING ASSOCIATIONS WITH THESE DYNAMIC BLOCKS ---

# 8. Route Table Associations (Dynamic)
# Associate the routing table to ALL public subnets
resource "aws_route_table_association" "public_subnet_routes_assn" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_subnet_routes.id
}

# Associate the routing table to ALL private subnets
resource "aws_route_table_association" "private_subnet_routes_assn" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_subnet_routes[count.index].id
}
# --- END NEW ASSOCIATION BLOCK --- this is to replace below 2 blocks
## Associate the routing table to public subnet A
#resource "aws_route_table_association" "public_subnet_routes_assn_a" {
#  subnet_id = "${aws_subnet.public_subnet_a.id}"
#  route_table_id = "${aws_route_table.public_subnet_routes.id}"
#}
#
## Associate the routing table to public subnet B
#resource "aws_route_table_association" "public_subnet_routes_assn_b" {
#  subnet_id = "${aws_subnet.public_subnet_b.id}"
#  route_table_id = "${aws_route_table.public_subnet_routes.id}"
#}

