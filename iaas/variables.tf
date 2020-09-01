# variables.tf

/*
variable "access_key" {
     default = "<PUT IN YOUR AWS ACCESS KEY>"
}
variable "secret_key" {
     default = "<PUT IN YOUR AWS SECRET KEY>"
}
*/
variable "region" {
  default = "eu-central-1"
}
variable "availabilityZone" {
  default = "eu-central-1a"
}
variable "instanceTenancy" {
  default = "default"
}
variable "dnsSupport" {
  default = true
}
variable "dnsHostNames" {
  default = true
}
variable "vpcCIDRblock" {
  default = "10.10.0.0/16"
}
variable "bastionCIDRblock" {
  default = "10.10.10.0/24"
}
variable "backendCIDRblock" {
  default = "10.10.20.0/24"
}
variable "destinationCIDRblock" {
  default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
  type    = list
  default = ["0.0.0.0/0"]
}
variable "egressCIDRblock" {
  type    = list
  default = ["0.0.0.0/0"]
}
variable "mapPublicIP" {
  default = true
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
variable "environment_tag" {
  description = "Environment tag"
  default     = "Production"
}

/*
variable "subnet_id" {}
variable "tags" {}
variable "boot" {}
*/
# end of variables.tf
