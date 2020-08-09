
variable "region" {
  default = "eu-central-1"
}
variable "public_key_path" {
  description = "Public key path"
  default     = "~/.ssh/ted.pub"
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

data "aws_iam_instance_profile" "SSM-S3" {
  name = "Jenkins"
}

# Create Public key
resource "aws_key_pair" "ec2key" {
  key_name   = "privateKey"
  public_key = file(var.public_key_path)
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

module "prod" {
  source = "./iaas/modules"
}

resource "aws_instance" "Backand" {
  ami                   = var.instance_ami
  instance_type         = var.instance_type
  iam_instance_profile  = data.aws_iam_instance_profile.SSM-S3.name
  subnet_id             = data.aws_subnet.sb_prv.id
  private_ip            = "10.10.20.10"
  secondary_private_ips = ["10.10.20.11"]
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
    yum update -y && yum install -y java #&& yum remove -y java-1.7.0-openjdk
    mkdir /app
    aws s3 sync s3://16-ted-search/app/ /app
    java -jar /app/embedash-1.1-SNAPSHOT.jar --spring.config.location=/app/application.properties
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
