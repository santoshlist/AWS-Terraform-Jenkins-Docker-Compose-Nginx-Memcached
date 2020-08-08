
provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

module "prod" {
  source = "./iaas/modules"
}
