provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "macos"
  public_key = file("~/.ssh/id_rsa.pub")
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "amz-webserver" {
  key_name      = aws_key_pair.ssh_key.key_name
  ami           = data.aws_ami.centos.id
  availability_zone = var.az
  instance_type = var.instance_size
  security_groups = ["${aws_security_group.web-server.name}"]
  user_data = <<-EOF
                #! /bin/bash
                sudo yum install epel-release -y && sudo yum update -y
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                device=$(lsblk -dp | awk '{print $1}' | tail -1);
                if [ -b "$device" ]; 
                   then sudo mkfs.xfs $device && sudo mount $device /var/www/html && echo "$device  /var/www/html  xfs  defaults  0  0" | sudo tee -a /etc/fstab ; 
                   else echo "Not Exist" >> /tmp/logfile ;
                fi
                echo "<h1>Hello AWS World" | sudo tee  /var/www/html/index.html
  EOF

  tags = {
        Name = "webserver"
  }

}

resource "aws_eip" "pub_static" {
  instance = aws_instance.amz-webserver.id
  vpc      = true
}

# creating and attaching ebs volume

resource "aws_ebs_volume" "data-vol" {
  availability_zone = var.az
  size = 1
  tags = {
        Name = "data-volume"
 }

}

resource "aws_volume_attachment" "web-data-vol" {
 device_name = "/dev/sdc"
 volume_id = aws_ebs_volume.data-vol.id
 instance_id = aws_instance.amz-webserver.id
}


output "pub_dns" {
  value = "${aws_eip.pub_static.public_dns}"
}
output "new_pub_address" {
  value = "${aws_eip.pub_static.public_ip}"
}
