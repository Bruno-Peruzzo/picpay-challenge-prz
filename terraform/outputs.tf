output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do API server do cluster."
  value       = module.eks.cluster_endpoint
}

output "region" {
  description = "Região AWS onde os recursos foram criados."
  value       = var.region
}

output "account_id" {
  description = "ID da conta AWS."
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "URL do repositório ECR da aplicação."
  value       = module.ecr.repository_url
}

output "lb_controller_role_arn" {
  description = "ARN da role IRSA do AWS Load Balancer Controller."
  value       = module.iam_irsa.lb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ARN da role IRSA do ExternalDNS."
  value       = module.iam_irsa.external_dns_role_arn
}

output "update_kubeconfig_command" {
  description = "Comando para configurar o kubeconfig local apos o apply."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${local.cluster_name}"
}
