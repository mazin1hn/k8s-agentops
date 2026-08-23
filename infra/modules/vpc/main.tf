#VPC 

resource "aws_vpc" "eks" {
    cidr_block = "10.0.0.0/16" #var.vpc_cidr_block
    enable_dns_hostnames = var.vpc_enable_dns_hostnames
    enable_dns_support = var.vpc_enable_dns_support

    tags = {
        Name = var.vpc_name  
    }
  
}

#Private Subnets 

resource "aws_subnet" "private" {
    for_each = {
        private_subnet_a = {
            cidr_block = var.private_subnet_a_cidr_block
            az = var.az_a
            name = var.private_subnet_a_name
        }
        
        private_subnet_b = {
            cidr_block = var.private_subnet_b_cidr_block
            az = var.az_b
            name = var.private_subnet_b_name
        }
    }

    vpc_id = aws_vpc.eks.id 
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az
    
    tags = {
  Name = each.value.name

  "kubernetes.io/cluster/eks_cluster" = "shared"
  "kubernetes.io/role/internal-elb"   = "1"
}
}

#Public Subnets 

resource "aws_subnet" "public" {
    for_each = {
        public_subnet_a = {
            cidr_block = var.public_subnet_a_cidr_block
            az = var.az_a
            name = var.public_subnet_a_name
        }
        
        public_subnet_b = {
            cidr_block = var.public_subnet_b_cidr_block
            az = var.az_b
            name = var.public_subnet_b_name
        }
    }

    vpc_id = aws_vpc.eks.id 
    cidr_block = each.value.cidr_block
    availability_zone = each.value.az
    
    tags = {
  Name = each.value.name

  "kubernetes.io/cluster/eks_cluster" = "shared"
  "kubernetes.io/role/elb"            = "1"
}

}

#Internet Gateway 


resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id
  

  tags = {
    Name = var.igw_name
  }
}

#Regional NAT Gateway 

resource "aws_nat_gateway" "eks" { 
    vpc_id = aws_vpc.eks.id
    availability_mode = var.nat_gw_availability_mode
    connectivity_type = var.nat_gw_connectivity_type
    
    tags = {
        Name = var.nat_gw_name
    }
}

#Route Tables 

resource "aws_route_table" "eks" {
    for_each = {
        public = { name = var.public_route_table_name } 
        private = { name = var.private_route_table_name }
    }

    vpc_id = aws_vpc.eks.id

    tags = {
     Name = each.value.name
    }
}

#Route Table: Routes 

resource "aws_route" "public_route" {
    route_table_id = aws_route_table.eks["public"].id
    destination_cidr_block = var.destination_cidr_block
    gateway_id = aws_internet_gateway.eks.id
  
}

resource "aws_route" "private_route" {
    route_table_id = aws_route_table.eks["private"].id
    destination_cidr_block = var.destination_cidr_block
    nat_gateway_id = aws_nat_gateway.eks.id
  
}

#Private Subnet's Route table association's

resource "aws_route_table_association" "private_route_table_association_a" {
  subnet_id      = aws_subnet.private["private_subnet_a"].id
  route_table_id = aws_route_table.eks["private"].id
}

resource "aws_route_table_association" "private_route_table_association_b" {
  subnet_id      = aws_subnet.private["private_subnet_b"].id
  route_table_id = aws_route_table.eks["private"].id
}

#Public Subnet's Route Table association's 

resource "aws_route_table_association" "public_route_table_association_a" {
  subnet_id      = aws_subnet.public["public_subnet_a"].id
  route_table_id = aws_route_table.eks["public"].id
}

resource "aws_route_table_association" "public_route_table_association_b" {
  subnet_id      = aws_subnet.public["public_subnet_b"].id
  route_table_id = aws_route_table.eks["public"].id
}





  



  



