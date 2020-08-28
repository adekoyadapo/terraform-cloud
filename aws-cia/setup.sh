#! /bin/bash
sudo yum install epel-release -y && sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
device=$(lsblk -dp | awk '{print $1}' | tail -1);
web_dir="/web"
if [ -b "$device" ];
   then sudo mkfs.xfs $device && sudo mkdir -p $web_dir && sudo mount $device $web_dir && echo "$device  $web_dir  xfs  defaults  0  0" | sudo tee -a /etc/fstab ;
   else echo "Not Exist" >> /tmp/logfile
fi
sudo mkdir -p $web_dir/html && sudo rm -rf /var/www/html
sudo ln -s $web_dir/html /var/www/html
if [ $? -ne 0 ]
then
    echo "DISABLED"
else
    echo "ENABLED"; sudo sed -i s/^SELINUX=.*$/SELINUX=permissive/ /etc/selinux/config; sudo setenforce 0
fi
echo "<h1>Hello AWS World</h1>" | sudo tee  $web_dir/html/index.html