output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public[*].id
}

output "private_subnet_id" {
  value = aws_subnet.private[*].id
}

output "nat_id" {
  value = aws_nat_gateway.nat[*].id
}

output "igw_id" {
  value = aws_internet_gateway.igw[*].id
}

output "public_rt_id" {
  value = aws_route_table.public-rt[*].id
}

output "default_rt_id" {
  value = aws_vpc.main.default_route_table_id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}