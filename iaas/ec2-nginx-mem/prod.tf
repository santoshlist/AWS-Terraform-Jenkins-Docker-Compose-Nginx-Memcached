
terraform {
  backend "s3" {
    bucket               = "ted-tfstate"
    key                  = "terraform/dev/prod.tfstate"
    region               = "eu-central-1"
    workspace_key_prefix = "terraform/workspace/prod-"
    dynamodb_table       = "ted-state-lock"
  }
}

data terraform_remote_state vpc {
  backend = "s3"
  config = {
    bucket = "ted-tfstate"
    key    = "terraform/dev/vpc.tfstate"
    region = "eu-central-1"
    workspace_key_prefix = "terraform/workspace/vpc-"
  }
}

data aws_security_group sg {
  name = "Ted VPC Security Group"
}

data aws_subnet sb_pub {
  cidr_block = var.bastionCIDRblock
}

data aws_subnet sb_prv {
  cidr_block = var.backendCIDRblock
}

data aws_iam_instance_profile SSM-S3 {
  name = "Jenkins"
}

data aws_route_table Backend_route_table {
  tags = {
    Name = "Private - Backend Route Table"
  }
}

output bastion-public-ip {
  value = aws_instance.Bastion.public_ip
}

resource aws_route Backend_Bastion_route {
  route_table_id         = data.aws_route_table.Backend_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id = aws_instance.Bastion.id
  depends_on = [
      aws_instance.Bastion,
      data.aws_route_table.Backend_route_table
  ]
}

resource aws_instance Bastion {
  ami                  = var.instance_nat
  instance_type        = var.instance_type
  iam_instance_profile = data.aws_iam_instance_profile.SSM-S3.name
  source_dest_check    = false
  subnet_id            = data.aws_subnet.sb_pub.id
  private_ip           = "10.10.10.10"
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  key_name                    = data.terraform_remote_state.vpc.outputs.public_key
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
    rm -f /usr/share/nginx/html/index.html
    aws s3 cp s3://16-ted-search/nginx.conf /etc/nginx/nginx.conf
    aws s3 sync s3://16-ted-search/static/ /usr/share/nginx/html
    ls /usr/share/nginx/html
    ls /usr/share/nginx/html > /nght.txt
    sudo chkconfig nginx on
    sudo service nginx start
	EOT
}

resource aws_instance Caching {
  count                 = var.instance_count
  ami                   = "ami-027aa2d9ec85953e1"
  instance_type         = var.instance_type
  subnet_id             = data.aws_subnet.sb_prv.id
  private_ip            = "10.10.20.3${count.index}"
  secondary_private_ips = ["10.10.20.4${count.index}"]
  key_name              = data.terraform_remote_state.vpc.outputs.public_key
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  tags = {
    Name        = "DB - Memchaced - # ${count.index + 1}"
    Environment = var.environment_tag
  }
}