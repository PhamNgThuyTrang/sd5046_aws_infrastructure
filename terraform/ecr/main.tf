module "ecr" {
  source      = "../modules/ecr"
  name        = "ecr"
  project     = "sd5046-aws-infrastructure"
  environment = "mgmt"
  owner       = "trangpham"
}
