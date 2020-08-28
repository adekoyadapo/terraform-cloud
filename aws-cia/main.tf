provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "macos"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "pub_static" {
  instance = aws_instance.amz-webserver.id
  vpc      = true
}

resource "aws_security_group" "web-server" {
  name = "web-server"
  description = "Web Security Group"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "amz-webserver" {
  depends_on = [ aws_security_group.web-server, aws_key_pair.ssh_key, ]
  key_name      = aws_key_pair.ssh_key.key_name
  ami           = data.aws_ami.centos.id
  availability_zone = var.az
  instance_type = var.instance_size
  security_groups = ["${aws_security_group.web-server.name}"]
  root_block_device {
    delete_on_termination = true
  }
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data = file("setup.sh")
  tags = {
        Name = "webserver"
  }
  provisioner "remote-exec" {
    when = destroy
    inline = ["sudo poweroff"]
    on_failure = continue

    connection {
        user = "centos"
        host = "aws_eip.pub_static.public_ip"
        private_key = file("~/.ssh/id_rsa")
      }
  }
}

# creating and attaching ebs volume

#resource "aws_ebs_volume" "data-vol" {
#  availability_zone = var.az
#  size = 1
#  tags = {
#        Name = "data-volume"
# }
#
#}

#resource "aws_volume_attachment" "web-data-vol" {
# device_name = "/dev/sdc"
# volume_id = aws_ebs_volume.data-vol.id
# instance_id = aws_instance.amz-webserver.id
#
#}
output "pub_dns" {
  value = "${aws_eip.pub_static.public_dns}"
}
output "new_pub_address" {
  value = "${aws_eip.pub_static.public_ip}"
}
