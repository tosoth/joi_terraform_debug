# Define a vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.5.0.0/16" # think about bigger cidr /12 or /14 for scale
  tags = {
    Name = "${var.prefix}"
    createdBy = "infra-${var.prefix}/base"
  }
}

# --- NEW CODE START ---
# Data source to fetch the list of available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}
# --- NEW CODE END ---

resource "aws_ssm_parameter" "vpc" {
  name = "/${var.prefix}/base/vpc_id"
  value = "${aws_vpc.vpc.id}"
  type  = "String"
}

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

# Internet gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Public gateway"
    createdBy = "infra-${var.prefix}/base"
  }
}

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

# Define the Public Subnets
resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Public subnets should map public IPs

  tags = {
    Name      = "${var.prefix}-public-${data.aws_availability_zones.available.names[count.index]}"
    createdBy = "infra-${var.prefix}/base"
  }
}

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

