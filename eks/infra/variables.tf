#VPC Variables (Can change per env)

variable "vpc_cidr_block" {
    type = string 
    
  
}

variable "private_subnet_a_cidr_block" {
    type = string 
    default = null
  
}

variable "private_subnet_b_cidr_block" {
    type = string 
    default = null
  
}

variable "public_subnet_a_cidr_block" {
    type = string 
    default = null
  
}

variable "public_subnet_b_cidr_block" {
    type = string 
    default = null
  
}

variable "az_a" {
    type = string 
    default = null
  
}

variable "az_b" {
    type = string 
    default = null
  
}