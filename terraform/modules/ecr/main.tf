# Módulo ECR — repositório privado de imagens da aplicação.

resource "aws_ecr_repository" "this" {
  name = var.repository_name

  # Tags imutáveis: a mesma tag nunca aponta p/ 2 imagens diferentes,
  # garantindo rastreabilidade e combinando com deploy GitOps por tag fixa.
  image_tag_mutability = "IMMUTABLE"

  # Permite que o `terraform destroy` apague o repositório mesmo com imagens
  # dentro. Essencial para o ciclo destroy/apply repetível e barato do desafio
  # (sem isso, o destroy falha com RepositoryNotEmptyException).
  force_delete = true

  # Scan de vulnerabilidades automático a cada push (segurança).
  image_scanning_configuration {
    scan_on_push = true
  }

  # Criptografia em repouso com chave gerenciada AWS (sem custo de KMS dedicado).
  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Lifecycle policy — controla custo de storage limpando imagens antigas.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        # Expira imagens não-tageadas (lixo de builds) após alguns dias.
        # rulePriority menor é avaliada primeiro pelo ECR.
        rulePriority = 1
        description  = "Expirar imagens nao-tageadas apos ${var.untagged_expire_days} dias"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expire_days
        }
        action = {
          type = "expire"
        }
      },
      {
        # Mantém apenas as últimas N imagens tageadas; expira as mais antigas.
        # tagStatus "any" precisa ser a regra de maior prioridade numérica (última).
        rulePriority = 2
        description  = "Manter as ${var.keep_last_images} imagens tageadas mais recentes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
