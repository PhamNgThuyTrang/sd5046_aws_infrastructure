output "backend_repo_url" {
  value       = module.ecr_backend.repo_url
  description = "Backend ECR repository URL"
}

output "frontend_repo_url" {
  value       = module.ecr_frontend.repo_url
  description = "Frontend ECR repository URL"
}

output "backend_repo_name" {
  value       = "sd5046-msa-backend"
  description = "Backend ECR repository name"
}

output "frontend_repo_name" {
  value       = "sd5046-msa-frontend"
  description = "Frontend ECR repository name"
}