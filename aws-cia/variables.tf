data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_ami" "centos" {
owners      = ["679593333241"]
most_recent = true

  filter {
      name   = "name"
      values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

variable "region" {
  default = "us-west-2"
}
variable "az" {
  default = "us-west-2a"
}
variable "image" {
  default = "ami-0c5b0e963f3f41645"
}
variable "instance_size" {
  default = "t2.micro"
}
