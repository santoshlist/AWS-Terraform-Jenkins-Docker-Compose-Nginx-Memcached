
terraform {
  backend "s3" {
    bucket               = "ted-tfstate"
    key                  = "terraform/dev/main.tfstate"
    region               = "eu-central-1"
    workspace_key_prefix = "terraform/workspace/main-"
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


variable "region" {
  default = "eu-central-1"
}
variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-0c115dbd34c69a004"
}
variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "t2.micro"
}
variable "backendCIDRblock" {
  default = "10.10.20.0/24"
}
variable "bastionCIDRblock" {
  default = "10.10.10.0/24"
}
variable "environment_tag" {
  description = "Environment tag"
  default     = "Production"
}

data "aws_security_group" "sg" {
  name = "Ted VPC Security Group"
}

data "aws_subnet" "sb_prv" {
  cidr_block = var.backendCIDRblock
}

data "aws_subnet" "sb_pub" {
  cidr_block = var.bastionCIDRblock
}

data "aws_iam_instance_profile" "SSM-S3" {
  name = "Jenkins"
}

provider "aws" {
  #profile = "default"
  region  = var.region
  version = "~> 3.0"
}

module "prod" {
  source = "./iaas/ec2-nginx-mem"
}

resource aws_instance Backend {
  ami                   = var.instance_ami
  instance_type         = var.instance_type
  iam_instance_profile  = data.aws_iam_instance_profile.SSM-S3.name
  subnet_id             = data.aws_subnet.sb_prv.id
  private_ip            = "10.10.20.10"
  secondary_private_ips = ["10.10.20.11"]
  key_name              = data.terraform_remote_state.vpc.outputs.public_key
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  tags = {
    Name        = "Backend - Ted Search App"
    Environment = var.environment_tag
  }
  user_data = <<EOT
    #!/bin/bash -xe
    yum update -y && yum install -y java
    mkdir /app
    aws s3 sync s3://16-ted-search/app/ /app
    java -jar /app/embedash-1.1-SNAPSHOT.jar --spring.config.location=/app/application.properties
	EOT
}

resource aws_instance Backup {
  ami                   = var.instance_ami
  instance_type         = var.instance_type
  iam_instance_profile  = data.aws_iam_instance_profile.SSM-S3.name
  subnet_id             = data.aws_subnet.sb_prv.id
  private_ip            = "10.10.20.20"
  secondary_private_ips = ["10.10.20.21"]
  key_name              = data.terraform_remote_state.vpc.outputs.public_key
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  tags = {
    Name        = "Backup - Backend - Ted Search App"
    Environment = var.environment_tag
  }
  user_data = <<EOT
    #!/bin/bash -xe
    yum update -y && yum install -y java
    mkdir /app
    aws s3 sync s3://16-ted-search/app/ /app
    java -jar /app/embedash-1.1-SNAPSHOT.jar --spring.config.location=/app/application.properties
	EOT
  /*
  provisioner "local-exec" {
    command = "echo ${aws_instance.Backup.id} > id_backup.txt"
  }
  */
}
output backend-id {
  value = aws_instance.Backend.id
}
output backup-id {
  value = aws_instance.Backup.id
}
output public_ip {
  value = module.prod.bastion-public-ip
}
output stg_public_ip {
  value = aws_instance.Staging.public_ip
}
resource aws_instance Staging {
  ami                   = var.instance_ami
  instance_type         = var.instance_type
  iam_instance_profile  = data.aws_iam_instance_profile.SSM-S3.name
  subnet_id             = data.aws_subnet.sb_pub.id
  key_name              = data.terraform_remote_state.vpc.outputs.public_key
  vpc_security_group_ids = [
    data.aws_security_group.sg.id
  ]
  tags = {
    Name        = "${terraform.workspace} - Ted Search App"
    Environment = "Staging"
  }
  //user_data = file("init.sh")
}