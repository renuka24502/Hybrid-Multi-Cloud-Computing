output "key_name" {
  value = aws_key_pair.cloudkey.key_name
}

output "sg_name" {
  value = aws_security_group.fe_sg.name
}

output "sg_id" {
  value = aws_security_group.fe_sg.id
}

output "instance_ip" {
  value = aws_instance.fe_1.public_ip
}

output "instance_name" {
  value = aws_instance.fe_1.tags
}

output "cloud_front" {
  value = aws_cloudfront_distribution.fe_cloudfront_distribution.id
}

output "cloud_data" {
  value = aws_cloudfront_distribution.fe_cloudfront_distribution.domain_name
}
