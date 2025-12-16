# Backend ECR Repository
module "ecr_backend" {
  source      = "../modules/ecr"
  name        = "sd5046-msa-backend"
  owner       = "trangpham"
}

# Frontend ECR Repository
module "ecr_frontend" {
  source      = "../modules/ecr"
  name        = "sd5046-msa-frontend"
  owner       = "trangpham"
}
