#EKS Cluster 

resource "aws_eks_cluster" "eks_cluster" {
    name = var.eks_cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn 
    version = var.eks_cluster_version
    
    access_config {

    authentication_mode = var.eks_cluster_authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.eks_cluster_bootstrap_cluster_creator_admin_permissions

  }
    
    vpc_config {
    
      subnet_ids = var.subnet_ids
      endpoint_private_access = var.eks_cluster_endpoint_private_access  
      endpoint_public_access =var.eks_cluster_endpoint_public_access 
      public_access_cidrs = [ "0.0.0.0/0" ] #temporary
    }

    enabled_cluster_log_types = var.enabled_cluster_log_types

depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role_policy,
  ]
}

#EKS Access Entry for the User 

resource "aws_eks_access_entry" "example" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = "arn:aws:iam::718875641991:user/mazin"
  type              = "STANDARD"
}

#Attatch policy to access entry

resource "aws_eks_access_policy_association" "example" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::718875641991:user/mazin"

  access_scope {
    type       = "cluster"
    
  }
}

#EKS Cluster IAM Role 

resource "aws_iam_role" "eks_cluster_role" {
    name = var.eks_cluster_role_name

    assume_role_policy = jsonencode({
         Version = var.eks_cluster_role_assume_role_policy_version  
     Statement = [
        {
             Effect = var.eks_cluster_role_assume_role_policy_effect
             Principal = {
                 Service = var.eks_cluster_role_assume_role_policy_service
            },
             Action = var.eks_cluster_role_assume_role_policy_action
        }
    ]
  
  })

    tags = {
        Name = "eks_cluster_iam_role"
    }
  
}

#EKS Cluster Role Policy Attachment 

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
    role = aws_iam_role.eks_cluster_role.name
    policy_arn = var.eks_cluster_role_policy_arn
  
}

    
       
  


#EKS Node Group

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids
  scaling_config {
    desired_size = var.eks_node_group_desired_size
    max_size     = var.eks_node_group_max_size
    min_size     = var.eks_node_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  ami_type = var.ami_type
  instance_types = var.instance_types

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only_policy,
  ]
}

#EKS Node Group IAM Roles

resource "aws_iam_role" "eks_node_group_role" {
    name = var.eks_node_group_role_name

    assume_role_policy = jsonencode({
         Version =  var.eks_node_group_role_assume_role_policy_version
     Statement = [
        {
             Effect = var.eks_node_group_role_assume_role_policy_effect
             Principal = {
                 Service = var.eks_node_group_role_assume_role_policy_service
            },
             Action = var.eks_node_group_role_assume_role_policy_action
        }
    ]
  
  })

    tags = {
        Name = "eks_node_group_iam_role"
    }
  
}


#EKS Node Group Role Policy Attachment 


resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
    role = aws_iam_role.eks_node_group_role.name
    policy_arn = var.ecr_read_only_policy_arn
  
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
    role = aws_iam_role.eks_node_group_role.name
    policy_arn = var.cni_policy_arn
  
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
    role = aws_iam_role.eks_node_group_role.name
    policy_arn = var.worker_node_policy_arn
  
}


#EKS Node Security Group 

resource "aws_security_group" "eks_node_sg" {
    name = var.eks_node_sg_name
    description = var.eks_node_sg_description
    vpc_id = var.vpc_id
  
# point: ADD SECOND INGRESS RULE ONLY ALLOWING TRAFFIC FROM ALB

    ingress {

    description = var.ingress_a_description
    from_port = var.ingress_a_from_port
    to_port     = var.ingress_a_to_port
    protocol  = var.ingress_a_protocol
    self = var.ingress_a_self_referencing

  }

    
    egress {

    description = var.egress_description
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol  = var.egress_protocol
    cidr_blocks = var.egress_cidr_blocks

  }

}



#ADDONS 

resource "aws_eks_addon" "vpc_cni" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    addon_name = var.vpc_cni_addon_name
    depends_on = [aws_eks_node_group.eks_node_group] 
    resolve_conflicts_on_create = var.addons_resolve_conflicts
    resolve_conflicts_on_update = var.addons_resolve_conflicts
  
}

resource "aws_eks_addon" "coredns" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    addon_name = var.coredns_addon_name
    depends_on = [aws_eks_node_group.eks_node_group] 
    resolve_conflicts_on_create = var.addons_resolve_conflicts
    resolve_conflicts_on_update = var.addons_resolve_conflicts

  
}

resource "aws_eks_addon" "kube_proxy" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    addon_name = var.kube_proxy_addon_name
    depends_on = [aws_eks_node_group.eks_node_group] 
    resolve_conflicts_on_create = var.addons_resolve_conflicts
    resolve_conflicts_on_update = var.addons_resolve_conflicts
  
}








