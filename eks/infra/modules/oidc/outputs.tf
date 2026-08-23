output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_driver_role.arn

}

output "external_dns_role_arn" {
    value = aws_iam_role.external_dns_role.arn
  
}