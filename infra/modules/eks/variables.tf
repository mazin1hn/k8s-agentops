

variable "subnet_ids" {
  type    = list(string)

}

variable "private_subnet_ids" {
    type = list(string)
  
}

variable "vpc_id" {
    type = string 
    default = null
  
}


#EKS Cluster 

#variable "my_ip" {
  #type    = string
  #default = "0.0.0.0"

#}   #temporory


variable "eks_cluster_name" {
    type = string 
    default = "eks_cluster"
  
}

variable "eks_cluster_version" {
    type = string 
    default = "1.35"
  
}

variable "eks_cluster_authentication_mode" {
    type = string 
    default = "API"
  
}

variable "eks_cluster_bootstrap_cluster_creator_admin_permissions" {
    type = bool
    default = true 
  
}

variable "eks_cluster_endpoint_private_access" {
    type = bool
    default = true 
  
}

variable "eks_cluster_endpoint_public_access" {
    type = bool
    default = true 
  
}

variable "enabled_cluster_log_types" {
    type = list(string)
    default = [ "api",
     "audit",
     "authenticator",
     "controllerManager",
     "scheduler" ]
  
}

#EKS Node group 

variable "eks_node_group_name" {
    type = string 
    default = "eks_node_group"
  
}

variable "eks_node_group_desired_size" {
    type = number 
    default = 2
  
}

variable "eks_node_group_max_size" {
    type = number 
    default = 3
  
}

variable "eks_node_group_min_size" {
    type = number 
    default = 2
  
}

variable "ami_type" {
    type = string 
    default = "AL2023_x86_64_STANDARD"
  
}

variable "instance_types" {
    type = list(string)
    default = ["m7i-flex.large"]
  
}



#EKS Node Group Role 

variable "eks_node_group_role_name" {
  type    = string
  default = "eks-node-group-role"

}

variable "eks_node_group_role_assume_role_policy_version" {
  type    = string
  default = "2012-10-17"

}

variable "eks_node_group_role_assume_role_policy_effect" {
  type    = string
  default = "Allow"

}

variable "eks_node_group_role_assume_role_policy_service" {
  type    = string
  default = "ec2.amazonaws.com"

}

variable "eks_node_group_role_assume_role_policy_action" {
  type    = string
  default = "sts:AssumeRole"

}

#EKS Node Group Policy Attatchment 

variable "ecr_pull_only_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"

}

variable "ecr_read_only_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

}

variable "cni_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

}

variable "worker_node_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

}

#EKS Cluster Role 

variable "eks_cluster_role_name" {
  type    = string
  default = "eks-cluster-role"

}

variable "eks_cluster_role_assume_role_policy_version" {
  type    = string
  default = "2012-10-17"

}

variable "eks_cluster_role_assume_role_policy_effect" {
  type    = string
  default = "Allow"

}

variable "eks_cluster_role_assume_role_policy_service" {
  type    = string
  default = "eks.amazonaws.com"

}

variable "eks_cluster_role_assume_role_policy_action" {
  type    = string
  default = "sts:AssumeRole"

}

#EKS Cluster Policy Attatchment 

variable "eks_cluster_role_policy_arn" {
  type    = string
  default = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

#ADDONS 

variable "vpc_cni_addon_name" {
    type = string 
    default = "vpc-cni"
  
}

variable "coredns_addon_name" {
    type = string 
    default = "coredns"
  
}

variable "kube_proxy_addon_name" {
    type = string 
    default = "kube-proxy"
  
}

variable "addons_resolve_conflicts" {
    type = string 
    default = "OVERWRITE"
  
}

#EKS Node Group Security Group 


variable "eks_node_sg_name" {
    type = string 
    default = "eks_node_sg"
  
}

variable "eks_node_sg_description" {
    type = string 
    default = "SG for the eks node group"
  
}

#Ingress A 

variable "ingress_a_description" {
    type = string 
    default = "Self referencing ingress rule to allow all traffic between nodes"
  
}

variable "ingress_a_from_port" {
    type = number 
    default = 0
  
}

variable "ingress_a_to_port" {
    type = number 
    default = 0
  
}

variable "ingress_a_protocol" {
    type = string
    default = "-1"
  
}
variable "ingress_a_self_referencing" {
    type = bool
    default = true
  
}

#Egress

variable "egress_description" {
    type = string 
    default = "Allow all outbound"
  
}

variable "egress_from_port" {
    type = number 
    default = 0
  
}

variable "egress_to_port" {
    type = number 
    default = 0
  
}

variable "egress_protocol" {
    type = string
    default = "-1"

}

variable "egress_cidr_blocks" {
    type = list(string)
    default = ["0.0.0.0/0"]
  
}
