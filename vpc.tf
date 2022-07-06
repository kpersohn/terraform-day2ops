locals {
  # Slice up VPC address space.
  # For example, consider a /16 VPC: carve up a /24 block (numbits=8) for each AZ,
  # then further split each block in half to form /25 public/private tiers. 
  # Each AZ is the outer element in the nested list so adding/removing AZs can occur 
  # without disrupting any live assets. 
  subnet_addresses = [
    for cidr_block in [
      for az in range(0, local.num_azs) : cidrsubnet(aws_vpc.main.cidr_block, 8, az)
    ] : cidrsubnets(cidr_block, 1, 1)
  ]
}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.env_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.env_name
  }
}

# Public Subnets

resource "aws_subnet" "public" {
  count                   = local.num_azs
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = local.subnet_addresses[count.index][0]
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.main.id

  tags = {
    Name = "${local.env_name}-public-${count.index}"
    tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.env_name}-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = local.num_azs
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnets

# resource "aws_subnet" "private" {
#   count             = local.num_azs
#   availability_zone = data.aws_availability_zones.available.names[count.index]
#   cidr_block        = local.subnet_addresses[count.index][1]
#   vpc_id            = aws_vpc.main.id

#   tags = {
#     Name = "${local.env_name}-private-${count.index}"
#     tier = "private"
#   }
# }

# resource "aws_eip" "natgw" {
#   count = local.num_azs
#   vpc   = true

#   tags = {
#     Name = "${local.env_name}-igw-eip-${count.index}"
#   }
# }

# resource "aws_nat_gateway" "main" {
#   count             = local.num_azs
#   allocation_id     = aws_eip.natgw[count.index].id
#   connectivity_type = "public"
#   subnet_id         = aws_subnet.public[0].id

#   tags = {
#     Name = "${local.env_name}-${count.index}"
#   }

#   depends_on = [aws_internet_gateway.main]
# }

# resource "aws_route_table" "private" {
#   count  = local.num_azs
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.main[count.index].id
#   }

#   tags = {
#     Name = "${local.env_name}-private"
#   }
# }

# resource "aws_route_table_association" "private" {
#   count          = local.num_azs
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }

# Use the following to build on existing VPC

# data aws_vpc "main" {
#   cidr_block = "10.0.0.0/16"
# }

# data "aws_subnets" "public" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.main.id]
#   }

#   filter {
#     name   = "tag:kubernetes.io/role/elb"
#     values = [1]
#   }
# }

# data "aws_subnet" "public" {
#   for_each = toset(data.aws_subnets.public.ids)
#   id       = each.value
# }

# data "aws_subnets" "private" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.main.id]
#   }

#   filter {
#     name   = "tag:kubernetes.io/role/internal-elb"
#     values = [1]
#   }
# }

# data "aws_subnet" "private" {
#   for_each = toset(data.aws_subnets.private.ids)
#   id       = each.value
# }
