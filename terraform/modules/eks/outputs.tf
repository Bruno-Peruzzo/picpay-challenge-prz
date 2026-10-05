output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do API server do cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado CA do cluster (base64) para autenticação do kubeconfig."
  value       = module.eks.cluster_certificate_authority_data
}

output "node_group_iam_role_name" {
  description = "Nome da IAM role do node group SPOT (usada para anexar policies dos controllers, já que não há IRSA)."
  value       = module.eks.eks_managed_node_groups["spot"].iam_role_name
}

output "node_group_iam_role_arn" {
  description = "ARN da IAM role do node group SPOT."
  value       = module.eks.eks_managed_node_groups["spot"].iam_role_arn
}
