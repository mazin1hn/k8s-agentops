#EKS 

variable "ecr_name" {
  type    = string
  default = "eks"

}

variable "ecr_image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"

}

variable "ecr_scan_on_push" {
  type    = bool
  default = true

}