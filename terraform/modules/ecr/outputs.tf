output "repository_url" {
  description = "URL do repositório ECR (usada no push/pull de imagens)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN do repositório ECR."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Nome do repositório ECR."
  value       = aws_ecr_repository.this.name
}
