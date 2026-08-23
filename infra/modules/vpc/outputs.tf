#VPC Outputs 

output "vpc_id" {
    description = "ID of the VPC"
    value = aws_vpc.eks.id 
  
}

output "igw_id" {
    description = "ID of the igw"
    value = aws_internet_gateway.eks.id
  
}

output "nat_gateway_id" {
    description = "ID of the NAT gateway"
    value = aws_nat_gateway.eks.id
  
}


output "private_subnet_ids" {
  description = "The IDS of both private subnets"
  value = values(aws_subnet.private)[*].id

}

output "public_subnet_ids" {
  description = "The IDS of both public subnets" 
  value = values(aws_subnet.public)[*].id
}
