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

output "node_group_iam_role_arn" {
  description = "ARN da role IAM do node group SPOT (informativo)."
  value       = module.eks.node_group_iam_role_arn
}

output "lb_controller_role_arn" {
  description = "ARN da IAM role do AWS Load Balancer Controller (via Pod Identity)."
  value       = module.pod_identity.lb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ARN da IAM role do ExternalDNS (via Pod Identity)."
  value       = module.pod_identity.external_dns_role_arn
}

output "ebs_csi_role_arn" {
  description = "ARN da IAM role do EBS CSI Driver (via Pod Identity)."
  value       = module.pod_identity.ebs_csi_role_arn
}

# Pares namespace/serviceAccount que o Helm DEVE usar (Fase 3) para que as
# associações de Pod Identity entreguem credenciais às pods dos controllers.
output "lb_controller_service_account" {
  description = "namespace/serviceAccount esperado pelo Helm do AWS Load Balancer Controller."
  value       = module.pod_identity.lb_controller_service_account
}

output "external_dns_service_account" {
  description = "namespace/serviceAccount esperado pelo Helm do ExternalDNS."
  value       = module.pod_identity.external_dns_service_account
}

output "update_kubeconfig_command" {
  description = "Comando para configurar o kubeconfig local apos o apply."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${local.cluster_name}"
}

# --- GitOps bootstrap (ArgoCD) ---

output "argocd_namespace" {
  description = "Namespace do ArgoCD."
  value       = module.platform.argocd_namespace
}

output "argocd_initial_admin_password_command" {
  description = "Comando para obter a senha inicial do admin do ArgoCD."
  value       = module.platform.argocd_initial_admin_password_command
}

output "argocd_ingress_hint" {
  description = "Comando para descobrir o hostname do ALB do ArgoCD (leva alguns minutos para provisionar)."
  value       = module.platform.argocd_ingress_hint
}

# --- DNS + TLS (Fase 7) ---

output "route53_name_servers" {
  description = "Nameservers do Route53 da hosted zone. Configurar no Namecheap (Domain > Nameservers > Custom DNS)."
  value       = module.dns.name_servers
}

output "acm_certificate_arn" {
  description = "ARN do certificado ACM wildcard validado. Já injetado no Ingress do ArgoCD; usar o mesmo nos Ingress de Grafana e app."
  value       = module.dns.certificate_arn
}

output "app_urls" {
  description = "URLs públicas das aplicações (HTTPS) após DNS propagar e ExternalDNS criar os registros."
  value = {
    argocd  = "https://argocd.${var.domain_name}"
    grafana = "https://grafana.${var.domain_name}"
    app     = "https://app.${var.domain_name}"
  }
}
