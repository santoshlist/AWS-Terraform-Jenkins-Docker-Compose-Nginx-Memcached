
terraform {
  backend "s3" {
    bucket               = "ted-tfstate"
    key                  = "terraform/dev/vpc.tfstate"
    region               = "eu-central-1"
    workspace_key_prefix = "terraform/workspace/vpc-"
    dynamodb_table       = "ted-state-lock"
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

/*
resource "aws_s3_bucket_object" "folder1" {
  bucket = "aws_s3_bucket"
  acl    = "public"
  key    = "Folder1/"
  source = "/dev/null"
}
*/
resource "aws_s3_bucket" "S3" {
  bucket = "16-ted-search"
  #acl = "private"
  #versioning {
  #  enabled = false
  #}
  tags = {
    Name = "16-Ted-Search"
  }
  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# create the VPC
resource "aws_vpc" "Ted-VPC" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy
  enable_dns_support   = var.dnsSupport
  enable_dns_hostnames = var.dnsHostNames
  tags = {
    Name = "Ted VPC"
  }
}

# Create the Security Group
resource "aws_security_group" "Ted-VPC_Security_Group" {
  vpc_id      = aws_vpc.Ted-VPC.id
  name        = "Ted VPC Security Group"
  description = "HTTP-SSH-SSL-ICMP-ALL"

  # allow ingress between the instances
  ingress {
    self      = true
    from_port = 0
    to_port   = 0
    protocol  = -1
  }

  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  # allow web http port 80
  ingress {
    cidr_blocks = var.ingressCIDRblock
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  # allow secure ssl port 443
  ingress {
    cidr_blocks = var.ingressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  # allow ICMP for ping
  ingress {
    cidr_blocks = var.ingressCIDRblock
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
  }

  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egressCIDRblock
  }

  tags = {
    Name        = "Ted VPC Security Group"
    Description = "HTTP-SSH-SSL-ICMP-ALL"
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "Ted_VPC_INGW" {
  vpc_id = aws_vpc.Ted-VPC.id
  tags = {
    Name = "Ted VPC Internet Gateway"
  }
}

# create public Subnet
resource "aws_subnet" "Bastion_Subnet" {
  vpc_id                  = aws_vpc.Ted-VPC.id
  cidr_block              = var.bastionCIDRblock
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = var.availabilityZone
  tags = {
    Name = "Public - Bastion Subnet"
  }
}

# Create Public Route Table
resource "aws_route_table" "Bastion_route_table" {
  vpc_id = aws_vpc.Ted-VPC.id
  tags = {
    Name = "Public - Bastion Route Table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "Bastion_association" {
  subnet_id      = aws_subnet.Bastion_Subnet.id
  route_table_id = aws_route_table.Bastion_route_table.id
}

# Create the Internet Access
resource "aws_route" "Bastion_internet_access" {
  route_table_id         = aws_route_table.Bastion_route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id             = aws_internet_gateway.Ted_VPC_INGW.id
}
/*
resource "aws_route" "Bastion_backend_route" {
  route_table_id         = aws_route_table.Bastion_route_table.id
  destination_cidr_block = "10.10.20.0/24"
}
*/
# create backend Subnet
resource "aws_subnet" "Backend_Subnet" {
  vpc_id            = aws_vpc.Ted-VPC.id
  cidr_block        = var.backendCIDRblock
  availability_zone = var.availabilityZone
  tags = {
    Name = "Private - Backend Subnet"
  }
}

# Create Private Route Table
resource "aws_route_table" "Backend_route_table" {
  vpc_id = aws_vpc.Ted-VPC.id
  tags = {
    Name = "Private - Backend Route Table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "Backend_association" {
  subnet_id      = aws_subnet.Backend_Subnet.id
  route_table_id = aws_route_table.Backend_route_table.id
}

resource "aws_iam_role" "EC2" {
  name        = "EC2"
  description = "Allow EC2 instance to assume IAM policy"
  tags = {
    Name    = "EC2"
    Roles   = "Trust - Assume role"
    Project = "Ted-Search"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF
}

resource "aws_iam_policy" "SSM-S3" {
  name        = "SSM-S3"
  description = "Allow instance access to SSM and S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeAssociation",
        "ssm:GetDeployablePatchSnapshotForInstance",
        "ssm:GetDocument",
        "ssm:DescribeDocument",
        "ssm:GetManifest",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:ListAssociations",
        "ssm:ListInstanceAssociations",
        "ssm:PutInventory",
        "ssm:PutComplianceItems",
        "ssm:PutConfigurePackageResult",
        "ssm:UpdateAssociationStatus",
        "ssm:UpdateInstanceAssociationStatus",
        "ssm:UpdateInstanceInformation"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2messages:AcknowledgeMessage",
        "ec2messages:DeleteMessage",
        "ec2messages:FailMessage",
        "ec2messages:GetEndpoint",
        "ec2messages:GetMessages",
        "ec2messages:SendReply"
      ],
      "Resource": "*"
    }
  ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "EC2-SSM-S3" {
  role       = aws_iam_role.EC2.name
  policy_arn = aws_iam_policy.SSM-S3.arn
}

resource "aws_iam_instance_profile" "Nginx-App" {
  name = "Jenkins"
  role = aws_iam_role.EC2.name
}

# Create Public key
resource "aws_key_pair" "ec2key" {
  key_name   = "privateKey"
  public_key = file(var.public_key_path)
}


/*
resource "aws_instance" "Bastion" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id //aws_subnet.Bastion_Subnet.id
  vpc_security_group_ids = [
    aws_security_group.Ted-VPC_Security_Group.id
  ]
  key_name                    = aws_key_pair.ec2key.key_name
  associate_public_ip_address = true
  tags                        = var.tags
  user_data                   = var.boot //<<EOT
}
*/
output "pub_sub" {
  value = aws_subnet.Bastion_Subnet.id
}

output "prv_sub" {
  value = aws_subnet.Backend_Subnet.id
}
/*
module "endpoint" {
  source = "./endpoint"
}
*/