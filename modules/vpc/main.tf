##########################VPC Module##########################
##############################################################

# Create the vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}"
  }
}

# If create_igw=true and length of publick subnets > 0
# Create internet gateway in vpc
resource "aws_internet_gateway" "igw" {
  count = var.create_igw && length(var.public_subnets) > 0 ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

###############Start define subnets######################
# Define private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id            = aws_vpc.main.id
  availability_zone = element(var.availability_zones, count.index)
  cidr_block        = var.private_subnets[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index}"
  }
}

# Define public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0
  
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(var.availability_zones, count.index)
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index}"
  }
}
###############End Create subnets######################




###############Start Create Public Route Table######################
# Create route for public subnet and attach to internet gateway
resource "aws_route_table" "public-rt" {
  count = var.create_igw && length(var.public_subnets) > 0 ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "associ_pub" {
  count = var.create_igw && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0
  
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  
  # As used count in aws_route_table, you have to
  # Use the specific route table
  route_table_id = aws_route_table.public-rt[0].id
}
###############End Create Public Route Table######################


###############Start Create NAT Gateway#####################
# Create elastic ip
resource "aws_eip" "nat_eip" {
  count = var.create_nat && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  vpc = true

  depends_on = [
    aws_internet_gateway.igw[0]
  ]
}

# Create nat gateway in each public subnet
resource "aws_nat_gateway" "nat" {
  count = var.create_nat && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  allocation_id = element(aws_eip.nat_eip[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)
}

###############End Create NAT Gateway#####################
