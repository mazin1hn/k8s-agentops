#VPC Variable

variable "vpc_cidr_block" { #Can change per env 
    type = string 
    
  
}

variable "vpc_enable_dns_hostnames" {
    type = bool 
    default = true 
  
}

variable "vpc_enable_dns_support" {
    type = bool
    default = true 
  
}

variable "vpc_name" {
    type = string
    default = "eks-vpc"
  
}

#Private Subnets

variable "private_subnet_a_cidr_block" {   #Can change per env 
    type = string 
    default = null
  
}


variable "private_subnet_a_name" {
    type = string 
    default = "private-subnet-a"
  
}

variable "private_subnet_b_cidr_block" {   #Can change per env 
    type = string 
    default = null
  
}


variable "private_subnet_b_name" {
    type = string 
    default = "private-subnet-b"
  
}


#Public Subnets 

variable "public_subnet_a_cidr_block" {   #Can change per env 
    type = string 
    default = null
  
}


variable "public_subnet_a_name" {
    type = string 
    default = "public-subnet-a"
  
}

variable "public_subnet_b_cidr_block" {   #Can change per env 
    type = string 
    default = null
  
}


variable "public_subnet_b_name" {
    type = string 
    default = "public-subnet-b"
  
}

#Availability zones

variable "az_a" {
    type = string 
    default = null
  
}

variable "az_b" {
    type = string 
    default = null
  
}

#Internet Gateway 

variable "igw_name" {
    type = string 
    default = "eks-igw"
  
}

#Regional NAT Gateway 

variable "nat_gw_availability_mode" {
    type = string 
    default = "regional"
  
}

variable "nat_gw_connectivity_type" {
    type = string 
    default = "public"
  
}

variable "nat_gw_name" {
    type = string 
    default = "eks-nat-gw"
  
}

#Route Tables 



variable "public_route_table_name" {
    type = string 
    default = "public-route-table"
  
}


variable "private_route_table_name" {
    type = string 
    default = "private-route-table"
  
}

#Route Tables: Routes 

variable "destination_cidr_block" {
    type = string 
    default = "0.0.0.0/0"
  
}

