output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet" {
  description = "The ID of the Public Subnet"
  value       = aws_subnet.public[*].id
}

output "private_subnet" {
  description = "The ID of the Private Subnet"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}
