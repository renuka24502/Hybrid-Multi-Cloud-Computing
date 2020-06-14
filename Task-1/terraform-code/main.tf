provider "aws" {
  region     = var.region
  version    = "~> 2.7"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY

}

resource "aws_key_pair" "cloudkey" {
  key_name = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "fe_sg" {
  name        = var.security_group_name
  description = "Allow TLS inbound traffic"

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_s3_bucket" "terraform-web-image" {
  bucket = var.bucket_name
  acl    = "public-read"
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }

}

resource "null_resource" "copy_image_to_s3" {

  depends_on = [
    aws_s3_bucket.terraform-web-image
  ]

  provisioner "local-exec" {
    command =  <<EOT
      if [ -d "${var.directory}" ]; then rm -Rf ${var.directory}; fi
      mkdir ${var.directory}
      git clone https://github.com/renuka24502/Hybrid-Multi-Cloud-Computing.git ${var.directory}
   EOT
  }
}

resource "aws_s3_bucket_object" "web_image_object" {
  depends_on = [
    null_resource.copy_image_to_s3
  ]

  bucket = aws_s3_bucket.terraform-web-image.bucket
  acl    = "public-read"
  key    = "/images/cloud.png"
  source = "${var.directory}/Task-1/images/CloudComputing.png"
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }

}

resource "aws_cloudfront_distribution" "fe_cloudfront_distribution" {

  depends_on = [
    aws_s3_bucket.terraform-web-image,
    null_resource.copy_image_to_s3
  ]

  origin {
    domain_name = aws_s3_bucket.terraform-web-image.bucket_regional_domain_name
    origin_id   = "mycloudcompute"
  }


  enabled             = true
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "mycloudcompute"


    forwarded_values {
      query_string = true


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_instance" "fe_1" {

  depends_on = [
    aws_key_pair.cloudkey,
    aws_security_group.fe_sg
  ]

  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name = aws_key_pair.cloudkey.key_name
  security_groups = [ aws_security_group.fe_sg.name ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file(var.private_key)
    host     = aws_instance.fe_1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "fe-1"
  }

}

resource "aws_ebs_volume" "fe_ebs" {
  availability_zone = aws_instance.fe_1.availability_zone
  size              = 1
  tags = {
    Name = "fe-ebs"
  }
}


resource "aws_volume_attachment" "fe_ebs_attachment" {
  depends_on = [
    aws_ebs_volume.fe_ebs
  ]
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.fe_ebs.id
  instance_id = aws_instance.fe_1.id
  force_detach = true
}

resource "null_resource" "copy_cloudfront_url" {

  depends_on = [
    aws_cloudfront_distribution.fe_cloudfront_distribution
  ]

  provisioner "local-exec" {
    command =  <<EOT
       echo '<html><h1>Hosted using Terraform</h1><body><img src="https://${aws_cloudfront_distribution.fe_cloudfront_distribution.domain_name}/index_image.jpeg" style="width:30%;height:70%;"></body></html>' > ${var.directory}/Task-1/scripts/index.html
       cd ${var.directory}
       git add Task-1/scripts/
       git commit -m "index.html file"
       git push origin master
   EOT
  }
}


resource "null_resource" "format_volume_mount"  {

depends_on = [
    aws_volume_attachment.fe_ebs_attachment,
    aws_cloudfront_distribution.fe_cloudfront_distribution,
    null_resource.copy_cloudfront_url
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file(var.private_key)
    host     = aws_instance.fe_1.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "if [ -d ${var.directory} ]; then rm -Rf ${var.directory}; fi",
      "sudo git clone https://github.com/renuka24502/Hybrid-Multi-Cloud-Computing.git ${var.directory}",
      "sudo cp ${var.directory}/Task-1/scripts/index.html  /var/www/html/",
    ]
  }
}
