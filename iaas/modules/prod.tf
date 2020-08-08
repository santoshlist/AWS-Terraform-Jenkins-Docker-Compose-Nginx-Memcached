
data "aws_security_group" "sg" {
  name = "Ted VPC Security Group"
}

data "aws_subnet" "sb_pub" {
  cidr_block = var.bastionCIDRblock
}

data "aws_subnet" "sb_prv" {
  cidr_block = var.backendCIDRblock
}

data "aws_iam_instance_profile" "SSM-S3" {
  name = "Jenkins"
}

# Create Public key
resource "aws_key_pair" "ec2key" {
  key_name   = "publicKey"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "Bastion" {
  ami                  = var.instance_ami
  instance_type        = var.instance_type
  iam_instance_profile = data.aws_iam_instance_profile.SSM-S3.name
  subnet_id            = data.aws_subnet.sb_pub.id
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  key_name                    = aws_key_pair.ec2key.key_name
  associate_public_ip_address = true
  tags = {
    Name        = "Bastion - Nginx Proxy"
    Environment = var.environment_tag
  }
  user_data = <<EOT
		#!/bin/bash -xe
    #exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    sudo amazon-linux-extras enable nginx1.12
		sudo yum clean metadata && sudo yum update -y && sudo yum -y install nginx
    sudo chkconfig nginx on
    sudo service nginx start
	EOT

  /*
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/terraform")
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras enable nginx1.12",
      "sudo yum clean metadata && sudo yum update -y && sudo yum -y install nginx",
      "#sudo rm -f /etc/nginx/nginx.conf",
      "#sudo cp -f terraform-ted-search/nginx.conf /etc/nginx/nginx.conf",
      "sudo chkconfig nginx on",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
  */
}

resource "aws_instance" "Backand" {
  ami                  = var.instance_ami
  instance_type        = var.instance_type
  iam_instance_profile = data.aws_iam_instance_profile.SSM-S3.name
  subnet_id            = data.aws_subnet.sb_prv.id
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  tags = {
    Name        = "Backend - Ted Search App"
    Environment = var.environment_tag
  }
  user_data = <<EOT
    #!/bin/bash -xe
    #exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    sudo amazon-linux-extras enable corretto8
    sudo yum clean metadata && sudo yum update -y && yum -y install java-1.8.0-amazon-corretto
	EOT
  /*
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras enable corretto8",
      "sudo yum clean metadata && sudo yum update -y && yum -y install java-1.8.0-amazon-corretto"
    ]
  }
  */
}

resource "aws_instance" "Caching" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.sb_prv.id
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  tags = {
    Name        = "DB - Memchaced"
    Environment = var.environment_tag
  }
  user_data = <<EOT
    #!/bin/bash -xe
    #exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    sudo yum update -y && sudo yum -y install memcached php70-pecl-memcached
    sudo sed -i 's|127.0.0.1|10.10.0.0|' /etc/sysconfig/memcached
    cat /etc/sysconfig/memcached
    sudo chkconfig memcached on
    sudo service memcached start
	EOT
  /*
  provisioner "remote-exec" {
    inline = [
      "sudo yum clean metadata && sudo yum update -y && sudo yum -y install memcached php70-pecl-memcached",
      "sudo sed -i 's|127.0.0.1|10.10.0.0|' /etc/sysconfig/memcached",
      "cat /etc/sysconfig/memcached",
      "sudo chkconfig memcached on",
      "sudo systemctl enable memcached",
      "sudo systemctl start memcached"
    ]
  }
  */
}

/*
module "Bastion" {
  source    = "./iaas"
  subnet_id = module.Bastion.pub_sub
  tags = {
    Name        = "Bastion - Nginx Proxy"
    Environment = var.environment_tag
  }
  boot = <<EOT
		#!/bin/bash -xe
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    sudo amazon-linux-extras enable nginx1.12
		sudo yum clean metadata && sudo yum update -y && sudo yum -y install nginx
    sudo chkconfig nginx on
    sudo service nginx start
	EOT
}

module "Backand" {
  source    = "./iaas"
  subnet_id = module.Backand.prv_sub
  tags = {
    Name        = "Backend - Ted Search App"
    Environment = var.environment_tag
  }
  boot = <<EOT
    #!/bin/bash -xe
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    sudo amazon-linux-extras enable corretto8
    sudo yum clean metadata && sudo yum update -y && yum -y install java-1.8.0-amazon-corretto
	EOT
}

module "DB" {
  source    = "./iaas"
  subnet_id = module.DB.prv_sub
  tags = {
    Name        = "DB - Memchaced"
    Environment = var.environment_tag
  }
  boot = <<EOT
    #!/bin/bash -xe
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    sudo yum clean metadata && sudo yum update -y && sudo yum -y install memcached php70-pecl-memcached
    sudo sed -i 's|127.0.0.1|10.10.0.0|' /etc/sysconfig/memcached
    cat /etc/sysconfig/memcached
    sudo chkconfig memcached on
    sudo service memcached start
	EOT
}
*

vpc_security_group_ids = [
    aws_security_group.Ted-VPC_Security_Group.id
  ]
*/

