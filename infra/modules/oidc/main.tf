# Connect IODC issuer url to IODC provider 


data "tls_certificate" "eks_oidc" {
  url = var.cluster_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "eks_pods" {
  url = var.cluster_oidc_issuer

  client_id_list = [ "sts.amazonaws.com",
  ]

  thumbprint_list = [ data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint ]
}

#EBS Driver IAM Role 

resource "aws_iam_role" "ebs_driver_role" {
    name = "ebs_driver_role"

   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_pods.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}


#EBS Driver Policy Attachment 


resource "aws_iam_role_policy_attachment" "ebs_policy" {

  role       = aws_iam_role.ebs_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

}

#External DNS IAM role 

resource "aws_iam_role" "external_dns_role" {
    name = "external_dns_role"

   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_pods.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:external-dns:external-dns"
        }
      }
    }]
  })
}

#External DNS IAM role policy creation 

resource "aws_iam_policy" "external_dns_policy" {
  name   = "external-dns-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

#External DNS IAM role policy attatchment 

resource "aws_iam_role_policy_attachment" "external_dns" {

  role       = aws_iam_role.external_dns_role.name
  policy_arn = aws_iam_policy.external_dns_policy.arn

}

#ArgodCD Image Updater IAM Policy

resource "aws_iam_policy" "image_updater_policy" {
  name = "argocd-image-updater-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeImages",
          "ecr:GetAuthorizationToken",
          "ecr:ListImages",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

#ArgodCD Image Updater IAM Role 

resource "aws_iam_role" "image_updater_role" {
  name = "argocd-image-updater-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_pods.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider}:sub" = "system:serviceaccount:argocd:argocd-image-updater"
        }
      }
    }]
  })
}

# Attach Policy 

resource "aws_iam_role_policy_attachment" "image_updater_attach" {
  role       = aws_iam_role.image_updater_role.name
  policy_arn = aws_iam_policy.image_updater_policy.arn
}






