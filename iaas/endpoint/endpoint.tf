variable "region" {
  default = "eu-central-1"
}

data aws_vpc Ted-VPC {
  tags = {
    Name = "Ted VPC"
  }
}

data "aws_security_group" "sg" {
  name = "Ted VPC Security Group"
}

data "aws_subnet" "sb_prv" {
  tags = {
    Name = "Private - Backend Subnet"
  }
}

data aws_route_table Backend_route_table {
  tags = {
    Name = "Private - Backend Route Table"
  }
}

resource aws_vpc_endpoint ssm {
  private_dns_enabled = true
  service_name        = join(".", ["com.amazonaws", var.region, "ssm"])
  vpc_endpoint_type   = "Interface"
  vpc_id              = data.aws_vpc.Ted-VPC.id

  security_group_ids = [
    data.aws_security_group.sg.id
  ]

  # Interface types get this. It connects the Endpoint to a subnet
  subnet_ids = [
    data.aws_subnet.sb_prv.id
  ]

  tags = merge(
    {
      Name = "service-endpoint-for-ssm"
      Tech = "Service Endpoint"
      Srv  = "VPC"
    }
  )
}

resource aws_vpc_endpoint ssmmessages {
  private_dns_enabled = true
  service_name        = join(".", ["com.amazonaws", var.region, "ssmmessages"])
  vpc_endpoint_type   = "Interface"
  vpc_id              = data.aws_vpc.Ted-VPC.id

  security_group_ids = [
    data.aws_security_group.sg.id
  ]

  # Interface types get this. It connects the Endpoint to a subnet
  subnet_ids = [
    data.aws_subnet.sb_prv.id
  ]

  tags = merge(
    {
      Name = "service-endpoint-for-ssm messages"
      Tech = "Service Endpoint"
      Srv  = "VPC"
    }
  )
}

resource aws_vpc_endpoint ec2 {
  private_dns_enabled = true
  service_name        = join(".", ["com.amazonaws", var.region, "ec2"])
  vpc_endpoint_type   = "Interface"
  vpc_id              = data.aws_vpc.Ted-VPC.id

  security_group_ids = [
    data.aws_security_group.sg.id
  ]

  # Interface types get this. It connects the Endpoint to a subnet
  subnet_ids = [
    data.aws_subnet.sb_prv.id
  ]

  tags = merge(
    {
      Name = "service-endpoint-for-ec2"
      Tech = "Service Endpoint"
      Srv  = "VPC"
    }
  )
}

resource aws_vpc_endpoint ec2messages {
  private_dns_enabled = true
  service_name        = join(".", ["com.amazonaws", var.region, "ec2messages"])
  vpc_endpoint_type   = "Interface"
  vpc_id              = data.aws_vpc.Ted-VPC.id

  security_group_ids = [
    data.aws_security_group.sg.id
  ]

  # Interface types get this. It connects the Endpoint to a subnet
  subnet_ids = [
    data.aws_subnet.sb_prv.id
  ]

  tags = merge(
    {
      Name = "service-endpoint-for-ec2 messages"
      Tech = "Service Endpoint"
      Srv  = "VPC"
    }
  )
}

resource aws_vpc_endpoint s3 {
  service_name = join(".", ["com.amazonaws", var.region, "s3"])
  vpc_id       = data.aws_vpc.Ted-VPC.id

  # Interface types get this. It connects the Endpoint to a route table
  route_table_ids = [
    data.aws_route_table.Backend_route_table.id
  ]

  tags = merge(
    {
      Name = "service-endpoint-for-ec2 messages"
      Tech = "Service Endpoint"
      Srv  = "VPC"
    }
  )
}
