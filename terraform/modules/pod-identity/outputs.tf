output "lb_controller_role_arn" {
  description = "ARN da IAM role associada à service account do AWS Load Balancer Controller (via Pod Identity)."
  value       = module.lb_controller.iam_role_arn
}

output "external_dns_role_arn" {
  description = "ARN da IAM role associada à service account do ExternalDNS (via Pod Identity)."
  value       = module.external_dns.iam_role_arn
}

output "ebs_csi_role_arn" {
  description = "ARN da IAM role associada à service account do EBS CSI Driver (via Pod Identity)."
  value       = module.ebs_csi.iam_role_arn
}

output "ebs_csi_addon_version" {
  description = "Versão instalada do addon aws-ebs-csi-driver."
  value       = aws_eks_addon.ebs_csi.addon_version
}

# Nomes de namespace/service account que o Helm DEVE usar para que a associação
# de Pod Identity funcione. Expostos como output para servirem de referência na
# configuração dos charts (Fase 3).
output "lb_controller_service_account" {
  description = "namespace/serviceAccount esperado pelo Helm do AWS Load Balancer Controller."
  value       = "${var.lb_controller_namespace}/${var.lb_controller_service_account}"
}

output "external_dns_service_account" {
  description = "namespace/serviceAccount esperado pelo Helm do ExternalDNS."
  value       = "${var.external_dns_namespace}/${var.external_dns_service_account}"
}
