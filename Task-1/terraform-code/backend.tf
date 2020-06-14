terraform {
  backend "s3" {
    bucket = "terraform-backend-files"
    key    = "task1/task1-state-tf"
    region = "ap-south-1"
  }
}
