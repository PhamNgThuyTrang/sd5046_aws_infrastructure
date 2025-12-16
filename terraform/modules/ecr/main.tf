module "ecr_tags" {
  source = "../tags"

  name        = var.name
  owner       = var.owner

  tags = {
    Description = "managed by terraform",
  }
}

resource "aws_ecr_repository" "default" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_scan_on_push
  }

  tags = module.ecr_tags.tags
}
