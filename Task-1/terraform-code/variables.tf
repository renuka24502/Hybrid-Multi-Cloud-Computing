variable "region" {
  default = "ap-south-1"
}

variable "AWS_ACCESS_KEY" {
  default = ""
}

variable "AWS_SECRET_KEY" {
  default = ""
}

variable "directory" {
  default = "/tmp/cloud"
}

variable "profile" {
  default = "renuka"
}

variable "key_name" {
  default = "cloudkey"
}

variable "public_key_path" {
  default = "../scripts/terraform.pub"
}

variable "private_key" {
  default = "~/.ssh/terraform"
}

variable "security_group_name" {
  default = "fe_sg"
}

variable "bucket_name" {
  default = "terraform-web-image"
}

variable "ami_id" {
  default = "ami-0447a12f28fddb066"
}